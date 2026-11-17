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
import world.zeds.ai.tools.GodotProject
import world.zeds.ai.tools.PdfReader
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
    val partial: String = "",
    val roleplay: Boolean = false,
    val project: String? = null,
    val savedFiles: List<String> = emptyList(),
    val previewHtml: String? = null,
    val error: String? = null,
)

class ZedViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = ModelRepository(app)
    private val engine = ChatEngine()
    private val workspace = Workspace(app)
    private var currentProject: Project? = null
    private var genJob: Job? = null

    private val _state = MutableStateFlow(UiState())
    val state = _state.asStateFlow()

    private val nCtx = 4096

    init {
        _state.update { it.copy(
            bundled = repo.isBundled(),
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

        val system = SystemPrompts.build(
            workshop = currentProject != null,
            roleplay = _state.value.roleplay,
        )

        genJob = viewModelScope.launch {
            val sb = StringBuilder()
            try {
                engine.stream(system, history, maxTokens = 1024, nCtx = nCtx).collect { piece ->
                    sb.append(piece)
                    _state.update { it.copy(partial = sb.toString()) }
                }
            } catch (e: Exception) {
                _state.update { it.copy(error = "generování selhalo: ${e.message}") }
            }
            val reply = sb.toString().trim()
            _state.update {
                it.copy(messages = it.messages + Msg(Msg.ASSISTANT, reply),
                        streaming = false, partial = "")
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

    fun dismissError() = _state.update { it.copy(error = null) }

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
    fun importPdf(uri: Uri, fileName: String, question: String) = viewModelScope.launch {
        _state.update { it.copy(status = "čtu PDF") }
        try {
            val r = PdfReader.extract(getApplication(), uri)
            if (r.needsOcr) {
                _state.update { it.copy(error =
                    "PDF nemá textovou vrstvu (asi sken). OCR se doplní ve fázi 5.") }
                return@launch
            }
            send(PdfReader.asPrompt(fileName, r, question))
        } catch (e: Exception) {
            _state.update { it.copy(error = "PDF nešlo přečíst: ${e.message}") }
        } finally {
            _state.update { it.copy(status = if (it.modelReady) "Zed připraven" else it.status) }
        }
    }
}
