package world.zeds.ai.ui

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import world.zeds.ai.llm.*
import world.zeds.ai.rp.Character
import world.zeds.ai.rp.CharacterStore
import world.zeds.ai.rp.CharacterWriter
import world.zeds.ai.memory.Chunker
import world.zeds.ai.memory.MemoryStore
import world.zeds.ai.memory.Note
import world.zeds.ai.tools.GodotProject
import world.zeds.ai.tools.PdfReader
import world.zeds.ai.tools.Toolchain
import world.zeds.ai.workspace.Artifacts
import world.zeds.ai.workspace.Project
import world.zeds.ai.workspace.Workspace
import java.io.File

data class UiState(
    val modelReady: Boolean = false,
    val bundled: Boolean = false,
    val loading: Boolean = false,
    val status: String = "",
    val downloadPercent: Int = -1,
    val messages: List<Msg> = emptyList(),
    val streaming: Boolean = false,
    /** Co Zed zrovna dělá – ukazuje se, dokud nezačne psát. */
    val phase: String = "",
    val startedAt: Long = 0L,
    val tokens: Int = 0,
    val partial: String = "",
    val roleplay: Boolean = false,
    val characters: List<Character> = emptyList(),
    val activeCharacter: Character? = null,
    val draftingCharacter: Boolean = false,
    val notes: List<Note> = emptyList(),
    val memoryUsed: Int = 0,
    val project: String? = null,
    val savedFiles: List<String> = emptyList(),
    val previewHtml: String? = null,
    val error: String? = null,
)

class ZedViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = ModelRepository(app)
    private val engine = ChatEngine()
    private val workspace = Workspace(app)
    private val characters = CharacterStore(app)
    private val memory = MemoryStore(app)
    private var currentProject: Project? = null
    private var genJob: Job? = null

    private val _state = MutableStateFlow(UiState())
    val state = _state.asStateFlow()

    private var nCtx = 4096

    init {
        _state.update { it.copy(
            bundled = repo.isBundled(),
            characters = characters.all(),
            notes = memory.all(),
            status = when {
                repo.isReady()   -> "model připraven k načtení"
                repo.isBundled() -> "model je v aplikaci, stačí rozbalit"
                else             -> "model chybí"
            },
        ) }
    }

    // ───────────────────────────────── model
    fun prepareModel() = viewModelScope.launch {
        if (!repo.isReady()) {
            val fromApk = repo.isBundled()
            _state.update { it.copy(loading = true,
                status = if (fromApk) "rozbaluji model z aplikace" else "stahuji model (~2,5 GB)") }
            try {
                val source = if (fromApk) repo.installFromAssets() else repo.download()
                source.collect { p -> _state.update { it.copy(downloadPercent = p.percent) } }
            } catch (e: Exception) {
                _state.update { it.copy(loading = false, downloadPercent = -1,
                    error = (if (fromApk) "rozbalení selhalo: " else "stahování selhalo: ") +
                            "${e.message}") }
                return@launch
            }
        }
        _state.update { it.copy(status = "načítám model do paměti", downloadPercent = -1) }
        val ok = withContext(Dispatchers.Default) {
            LlamaBridge.load(repo.modelFile.absolutePath, nCtx = nCtx)
                .also { if (it) nCtx = LlamaBridge.contextSize().coerceAtLeast(512) }
        }
        _state.update {
            it.copy(loading = false, modelReady = ok,
                status = if (ok) "Zed připraven" else "model se nepodařilo načíst",
                error = if (ok) null else "llama.cpp model nenačetl – zkontroluj, že je GGUF celý")
        }
    }

    override fun onCleared() { LlamaBridge.unload() }

    // ───────────────────────────────── chat
    fun send(text: String) {
        if (text.isBlank() || _state.value.streaming) return
        val history = _state.value.messages + Msg(Msg.USER, text)
        _state.update { it.copy(messages = history, streaming = true, partial = "") }

        _state.update { it.copy(
            phase = "čtu paměť",
            startedAt = System.currentTimeMillis(),
            tokens = 0,
        ) }
        val recalled = memory.recall(text)
        val system = SystemPrompts.build(
            workshop = currentProject != null,
            roleplay = _state.value.roleplay,
            character = _state.value.activeCharacter
                ?.takeIf { _state.value.roleplay && !it.isBlank }
                ?.asPrompt(),
            memory = memory.recallPrompt(text),
            environment = Toolchain.forPrompt(getApplication()),
        )
        _state.update { it.copy(
            memoryUsed = recalled.size,
            phase = when {
                recalled.isNotEmpty() -> "našel ${recalled.size} poznámek, přemýšlím"
                currentProject != null -> "přemýšlím nad kódem"
                it.roleplay -> "vedu scénu"
                else -> "přemýšlím"
            },
        ) }

        genJob = viewModelScope.launch {
            val sb = StringBuilder()
            try {
                engine.stream(system, history, maxTokens = 1024, nCtx = nCtx).collect { piece ->
                    sb.append(piece)
                    // První token znamená, že prompt je zpracovaný a Zed píše.
                    _state.update {
                        it.copy(partial = sb.toString(), phase = "", tokens = it.tokens + 1)
                    }
                }
            } catch (e: Exception) {
                _state.update { it.copy(error = "generování selhalo: ${e.message}") }
            }
            val reply = sb.toString().trim()
            _state.update {
                it.copy(messages = it.messages + Msg(Msg.ASSISTANT, reply),
                        streaming = false, partial = "", phase = "")
            }
            saveArtifacts(reply)
        }
    }

    fun stop() { engine.requestStop(); genJob?.cancel() }

    fun clearChat() {
        LlamaBridge.resetContext()
        _state.update { it.copy(messages = emptyList(), partial = "", savedFiles = emptyList()) }
    }

    fun toggleRoleplay() = _state.update { it.copy(roleplay = !it.roleplay) }

    // ───────────────────────────────── RP postavy
    fun saveCharacter(c: Character) {
        characters.save(c)
        _state.update { st ->
            st.copy(
                characters = characters.all(),
            notes = memory.all(),
                activeCharacter = if (st.activeCharacter?.id == c.id) c else st.activeCharacter,
            )
        }
    }

    fun deleteCharacter(c: Character) {
        characters.delete(c)
        _state.update { st ->
            st.copy(
                characters = characters.all(),
            notes = memory.all(),
                activeCharacter = st.activeCharacter?.takeIf { it.id != c.id },
            )
        }
    }

    /** Vybraná postava se vkládá do promptu; stejný výběr ji odepne. */
    fun selectCharacter(c: Character?) = _state.update {
        val next = if (c != null && c.id == it.activeCharacter?.id) null else c
        it.copy(activeCharacter = next, roleplay = it.roleplay || next != null)
    }

    /**
     * Nechá Zeda vyplnit kartu postavy z pár slov. Běží mimo chat,
     * aby návrh postavy nezaplevelil rozehranou scénu.
     */
    fun draftCharacter(brief: String, onReady: (Character) -> Unit) {
        if (!_state.value.modelReady || _state.value.draftingCharacter) return
        _state.update { it.copy(draftingCharacter = true) }
        viewModelScope.launch {
            val sb = StringBuilder()
            try {
                engine.stream(
                    SystemPrompts.ZED,
                    listOf(Msg(Msg.USER, CharacterWriter.prompt(brief))),
                    maxTokens = 400, nCtx = nCtx,
                ).collect { sb.append(it) }
                onReady(CharacterWriter.parse(sb.toString()))
            } catch (e: Exception) {
                _state.update { it.copy(error = "postavu se nepovedlo vymyslet: ${e.message}") }
            } finally {
                LlamaBridge.resetContext()
                _state.update { it.copy(draftingCharacter = false) }
            }
        }
    }

    fun dismissError() = _state.update { it.copy(error = null) }

    // ───────────────────────────────── paměť
    fun saveNote(n: Note) {
        memory.save(n)
        _state.update { it.copy(notes = memory.all()) }
    }

    fun deleteNote(n: Note) {
        memory.delete(n)
        _state.update { it.copy(notes = memory.all()) }
    }

    /** Smaže všechno, co přišlo z jednoho PDF. */
    fun forgetSource(source: String) {
        memory.deleteSource(source)
        _state.update { it.copy(notes = memory.all()) }
    }

    fun memorySources(): List<String> = memory.sources()

    // ───────────────────────────────── dílna
    fun openProject(name: String) {
        val p = workspace.projects().firstOrNull { it.name == name } ?: workspace.create(name)
        currentProject = p
        _state.update { it.copy(project = p.name, savedFiles = p.files().map {
            f -> f.relativeTo(p.dir).path }) }
    }

    fun closeProject() {
        currentProject = null
        _state.update { it.copy(project = null, savedFiles = emptyList(), previewHtml = null) }
    }

    fun projectNames(): List<String> = workspace.projects().map { it.name }

    private fun saveArtifacts(reply: String) {
        val p = currentProject ?: return
        val saved = Artifacts.saveAll(p, reply)
        if (saved.isEmpty()) return
        _state.update { it.copy(savedFiles = p.files().map { f -> f.relativeTo(p.dir).path }) }
        p.entryHtml()?.let { html -> _state.update { it.copy(previewHtml = html.readText()) } }
    }

    fun showPreview(relativePath: String) {
        val p = currentProject ?: return
        val content = p.read(relativePath) ?: return
        val html = when (File(relativePath).extension.lowercase()) {
            "html", "htm" -> content
            "svg" -> "<!doctype html><body style=\"margin:0;background:#14110F\">$content"
            else -> "<!doctype html><body style=\"background:#14110F;color:#EDE4DA\">" +
                    "<pre style=\"white-space:pre-wrap;padding:12px\">" +
                    content.replace("&", "&amp;").replace("<", "&lt;") + "</pre>"
        }
        _state.update { it.copy(previewHtml = html) }
    }

    fun closePreview() = _state.update { it.copy(previewHtml = null) }

    fun exportGodotZip(): File? {
        val p = currentProject ?: return null
        val out = File(getApplication<Application>().cacheDir, "${p.name}.zip")
        return runCatching { GodotProject.zip(p, out) }.getOrNull()
    }

    // ───────────────────────────────── PDF
    /**
     * @param toMemory true uloží PDF natrvalo do paměti; false ho jen
     *                 jednou přiloží k dotazu.
     */
    fun importPdf(
        uri: Uri,
        fileName: String,
        question: String,
        toMemory: Boolean = false,
    ) = viewModelScope.launch {
        _state.update { it.copy(phase = if (toMemory) "učím se z PDF" else "čtu PDF") }
        try {
            val r = PdfReader.extract(getApplication(), uri)
            if (r.needsOcr) {
                _state.update { it.copy(error =
                    "PDF nemá textovou vrstvu (asi sken). OCR se doplní ve fázi 5.") }
                return@launch
            }
            if (toMemory) {
                memory.deleteSource(fileName)          // druhý import nic nezdvojí
                val chunks = Chunker.chunk(r.text, fileName)
                if (chunks.isEmpty()) {
                    _state.update { it.copy(error = "v PDF nebyl žádný použitelný text") }
                    return@launch
                }
                memory.add(chunks)
                _state.update { it.copy(
                    notes = memory.all(),
                    status = "do paměti přibylo ${chunks.size} poznámek z $fileName",
                ) }
                return@launch
            }
            send(PdfReader.asPrompt(fileName, r, question))
        } catch (e: Exception) {
            _state.update { it.copy(error = "PDF nešlo přečíst: ${e.message}") }
        } finally {
            _state.update { it.copy(phase = "") }
        }
    }
}
