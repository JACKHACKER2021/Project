package world.zeds.ai.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import world.zeds.ai.llm.Msg
import world.zeds.ai.rp.Character
import world.zeds.ai.memory.Note

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(vm: ZedViewModel) {
    val s by vm.state.collectAsState()
    var input by remember { mutableStateOf("") }
    var pdfQuestion by remember { mutableStateOf("") }
    var showProjects by remember { mutableStateOf(false) }
    var showCharacters by remember { mutableStateOf(false) }
    var editing by remember { mutableStateOf<Character?>(null) }
    var showMemory by remember { mutableStateOf(false) }
    var editingNote by remember { mutableStateOf<Note?>(null) }
    var pdfToMemory by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    val pickPdf = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let {
            vm.importPdf(
                it,
                it.lastPathSegment?.substringAfterLast('/') ?: "dokument.pdf",
                pdfQuestion,
                toMemory = pdfToMemory,
            )
            pdfQuestion = ""
            pdfToMemory = false
        }
    }

    // Autoscroll při streamování
    LaunchedEffect(s.messages.size, s.partial) {
        val last = s.messages.size   // + případná rozepsaná zpráva
        if (last > 0) listState.animateScrollToItem(last)
    }

    s.previewHtml?.let { html ->
        PreviewSheet(html = html, onClose = vm::closePreview)
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Zed", style = MaterialTheme.typography.titleMedium)
                        Text(s.project?.let { "dílna · $it" }
                            ?: s.activeCharacter?.let { "hraješ · ${it.name}" }
                            ?: s.status,
                            style = MaterialTheme.typography.labelSmall)
                    }
                },
                actions = {
                    IconToggleButton(checked = s.roleplay, onCheckedChange = { vm.toggleRoleplay() }) {
                        Icon(Icons.Filled.TheaterComedy,
                            contentDescription = if (s.roleplay) "RP zapnuto" else "RP vypnuto")
                    }
                    IconButton(onClick = { showMemory = true }) {
                        Icon(Icons.Filled.Psychology, contentDescription = "Paměť")
                    }
                    IconButton(onClick = { showCharacters = true }) {
                        Icon(
                            if (s.activeCharacter != null) Icons.Filled.Person
                            else Icons.Filled.PersonOutline,
                            contentDescription = "Postavy",
                        )
                    }
                    IconButton(onClick = { showProjects = true }) {
                        Icon(Icons.Filled.FolderOpen, contentDescription = "Dílna")
                    }
                    IconButton(onClick = vm::clearChat) {
                        Icon(Icons.Filled.DeleteSweep, contentDescription = "Nová konverzace")
                    }
                },
            )
        },
        bottomBar = {
            if (s.modelReady) InputBar(
                value = input,
                onValue = { input = it },
                streaming = s.streaming,
                onSend = { vm.send(input); input = "" },
                onStop = vm::stop,
                onPdf = { pdfQuestion = input; input = ""; pickPdf.launch(arrayOf("application/pdf")) },
            )
        },
    ) { pad ->
        Box(Modifier.padding(pad).fillMaxSize()) {
            when {
                !s.modelReady -> SetupPane(s, onStart = vm::prepareModel)
                else -> LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    if (s.messages.isEmpty() && s.partial.isEmpty()) {
                        item { EmptyHint(s.roleplay, s.project != null, onPick = { input = it }) }
                    }
                    items(s.messages) { Bubble(it.role, it.content) }
                    if (s.partial.isNotEmpty()) item {
                        Column {
                            Bubble(Msg.ASSISTANT, s.partial)
                            WritingStats(s.tokens, s.startedAt)
                        }
                    }
                    // Než dorazí první token, musí model přežvýkat celý prompt;
                    // na telefonu to je klidně půl minuty a bez tohohle to
                    // vypadá zaseknutě.
                    if (s.streaming && s.partial.isEmpty()) item {
                        ThinkingBubble(s.phase, s.startedAt)
                    }
                    if (s.savedFiles.isNotEmpty()) item {
                        SavedFiles(s.savedFiles, onOpen = vm::showPreview)
                    }
                }
            }
        }
    }

    if (showMemory) MemorySheet(
        notes = s.notes,
        onEdit = { editingNote = it; showMemory = false },
        onDelete = { vm.deleteNote(it) },
        onForgetSource = { vm.forgetSource(it) },
        onNew = { editingNote = Note(); showMemory = false },
        onImportPdf = {
            pdfToMemory = true
            showMemory = false
            pickPdf.launch(arrayOf("application/pdf"))
        },
        onDismiss = { showMemory = false },
    )

    editingNote?.let { note ->
        NoteEditor(
            initial = note,
            onSave = { vm.saveNote(it); editingNote = null },
            onDismiss = { editingNote = null },
        )
    }

    if (showCharacters) CharacterSheet(
        characters = s.characters,
        active = s.activeCharacter,
        onSelect = { vm.selectCharacter(it) },
        onEdit = { editing = it; showCharacters = false },
        onDelete = { vm.deleteCharacter(it) },
        onNew = { editing = Character(); showCharacters = false },
        onDismiss = { showCharacters = false },
    )

    editing?.let { draft ->
        CharacterEditor(
            initial = draft,
            drafting = s.draftingCharacter,
            canDraft = s.modelReady,
            onDraft = { brief ->
                vm.draftCharacter(brief) { made -> editing = made.copy(id = draft.id) }
            },
            onSave = { vm.saveCharacter(it); vm.selectCharacter(it); editing = null },
            onDismiss = { editing = null },
        )
    }

    if (showProjects) ProjectSheet(
        projects = vm.projectNames(),
        current = s.project,
        onOpen = { vm.openProject(it); showProjects = false },
        onClose = { vm.closeProject(); showProjects = false },
        onDismiss = { showProjects = false },
    )

    s.error?.let { msg ->
        AlertDialog(
            onDismissRequest = vm::dismissError,
            title = { Text("Nepovedlo se") },
            text = { Text(msg) },
            confirmButton = { TextButton(onClick = vm::dismissError) { Text("OK") } },
        )
    }
}

@Composable
private fun SetupPane(s: UiState, onStart: () -> Unit) = Column(
    Modifier.fillMaxSize().padding(28.dp),
    verticalArrangement = Arrangement.Center,
    horizontalAlignment = Alignment.CenterHorizontally,
) {
    Text("Zeds World", style = MaterialTheme.typography.headlineMedium)
    Spacer(Modifier.height(6.dp))
    Text("Model běží offline v telefonu.", style = MaterialTheme.typography.bodyMedium)
    Spacer(Modifier.height(28.dp))

    when {
        s.downloadPercent >= 0 -> {
            LinearProgressIndicator(
                progress = { s.downloadPercent / 100f },
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(10.dp))
            Text("${s.downloadPercent} % · ${s.status}")
            Spacer(Modifier.height(4.dp))
            Text(
                if (s.bundled) "Jednorázové rozbalení. Potom aplikace nepotřebuje internet."
                else "Stahování lze přerušit a pokračovat později.",
                style = MaterialTheme.typography.labelSmall,
            )
        }
        s.loading -> { CircularProgressIndicator(); Spacer(Modifier.height(10.dp)); Text(s.status) }
        else -> {
            Button(onClick = onStart) {
                Text(if (s.bundled) "Rozbalit model" else "Stáhnout model")
            }
            Spacer(Modifier.height(10.dp))
            Text(s.status, style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
private fun EmptyHint(rp: Boolean, workshop: Boolean, onPick: (String) -> Unit) = Column(
    Modifier.fillMaxWidth().padding(horizontal = 20.dp),
    horizontalAlignment = Alignment.CenterHorizontally,
) {
    Spacer(Modifier.height(80.dp))
    Text("✴", style = MaterialTheme.typography.displayMedium,
        color = MaterialTheme.colorScheme.primary)
    Spacer(Modifier.height(12.dp))
    Text(
        when {
            rp -> "Kdo dneska jsi?"
            workshop -> "Co postavíme?"
            else -> "Co tě zajímá?"
        },
        style = MaterialTheme.typography.headlineMedium,
    )

    Spacer(Modifier.height(56.dp))

    val tips = when {
        rp -> listOf(
            Icons.Filled.TheaterComedy to "Začni scénu v Normalpolisu",
            Icons.Filled.Person to "Hraju svou postavu, veď svět",
            Icons.Filled.Bolt to "Hoď mě do průšvihu",
        )
        workshop -> listOf(
            Icons.Filled.Code to "Napiš GDScript pro pohyb hráče",
            Icons.Filled.Language to "Udělej stránku o Zeds World",
            Icons.Filled.ViewInAr to "Scéna ve three.js",
        )
        else -> listOf(
            Icons.Filled.AutoStories to "Napiš povídku ze Sektoru EX",
            Icons.Filled.Psychology to "Co víš o Zeds World?",
            Icons.Filled.PictureAsPdf to "Nauč se lore z mého PDF",
        )
    }
    tips.forEach { (icon, text) ->
        Row(
            Modifier
                .fillMaxWidth()
                .clickable { onPick(text) }
                .padding(vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(icon, null, Modifier.size(22.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.width(18.dp))
            Text(text, style = MaterialTheme.typography.bodyLarge)
        }
    }
}

/**
 * Rychlost psaní a dokdy nejpozději skončí. Přesný čas konce se říct
 * nedá – kdy přestane, rozhoduje sám model – takže se ukazuje horní
 * mez spočítaná ze zbývajícího limitu tokenů.
 */
@Composable
private fun WritingStats(tokens: Int, startedAt: Long) {
    var now by remember(startedAt) { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(startedAt) {
        while (true) { kotlinx.coroutines.delay(500); now = System.currentTimeMillis() }
    }
    val secs = ((now - startedAt) / 1000.0).coerceAtLeast(0.1)
    if (tokens < 3) return
    val rate = tokens / secs
    val worst = ((1024 - tokens).coerceAtLeast(0) / rate).toInt()
    Text(
        "%.1f tok/s · %ds · nejdéle ještě ~%ds".format(rate, secs.toInt(), worst),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = 6.dp, top = 2.dp),
    )
}

/** Co Zed dělá, dokud nezačne psát – plus kolik to už trvá. */
@Composable
private fun ThinkingBubble(phase: String, startedAt: Long) {
    var seconds by remember(startedAt) { mutableIntStateOf(0) }
    LaunchedEffect(startedAt) {
        while (true) {
            kotlinx.coroutines.delay(1000)
            seconds = ((System.currentTimeMillis() - startedAt) / 1000).toInt()
        }
    }
    Row(
        Modifier
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CircularProgressIndicator(Modifier.size(14.dp), strokeWidth = 2.dp)
        Spacer(Modifier.width(10.dp))
        Text(
            phase.ifBlank { "přemýšlím" } + if (seconds > 2) "  ·  ${seconds}s" else "",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun Bubble(role: String, content: String) {
    val mine = role == Msg.USER
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Surface(
            shape = RoundedCornerShape(14.dp),
            color = if (mine) MaterialTheme.colorScheme.primaryContainer
                    else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.widthIn(max = 340.dp),
        ) {
            SelectionContainer {
                Text(
                    content,
                    modifier = Modifier.padding(12.dp),
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontFamily = if (content.contains("```")) FontFamily.Monospace
                                     else FontFamily.Default,
                    ),
                )
            }
        }
    }
}

@Composable
private fun SavedFiles(files: List<String>, onOpen: (String) -> Unit) =
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(12.dp)) {
            Text("Soubory v projektu", style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.height(6.dp))
            files.forEach { f ->
                TextButton(onClick = { onOpen(f) }, contentPadding = PaddingValues(vertical = 2.dp)) {
                    Icon(Icons.Filled.Description, null, Modifier.size(16.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(f, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }

@Composable
private fun InputBar(
    value: String, onValue: (String) -> Unit, streaming: Boolean,
    onSend: () -> Unit, onStop: () -> Unit, onPdf: () -> Unit,
) = Surface(
    shape = RoundedCornerShape(30.dp),
    color = MaterialTheme.colorScheme.surfaceVariant,
    modifier = Modifier
        .fillMaxWidth()
        // Aplikace kreslí pod systémové lišty, takže si vstup musí
        // uhnout navigaci i vyjeté klávesnici sám.
        .navigationBarsPadding()
        .imePadding()
        .padding(horizontal = 12.dp, vertical = 10.dp),
) {
    Row(
        Modifier.padding(start = 6.dp, end = 6.dp, top = 5.dp, bottom = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onPdf, enabled = !streaming) {
            Icon(Icons.Filled.Add, "Přiložit PDF")
        }
        TextField(
            value = value,
            onValueChange = onValue,
            placeholder = { Text("Zeptej se Zeda") },
            maxLines = 5,
            modifier = Modifier.weight(1f),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
            ),
        )
        FilledIconButton(
            onClick = if (streaming) onStop else onSend,
            enabled = streaming || value.isNotBlank(),
            modifier = Modifier.size(44.dp),
        ) {
            Icon(
                if (streaming) Icons.Filled.Stop else Icons.Filled.ArrowUpward,
                contentDescription = if (streaming) "Zastavit" else "Poslat",
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProjectSheet(
    projects: List<String>, current: String?,
    onOpen: (String) -> Unit, onClose: () -> Unit, onDismiss: () -> Unit,
) {
    var newName by remember { mutableStateOf("") }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(16.dp).navigationBarsPadding()) {
            Text("Dílna", style = MaterialTheme.typography.titleMedium)
            Spacer(Modifier.height(4.dp))
            Text("Když je projekt otevřený, Zed ukládá kód do souborů.",
                style = MaterialTheme.typography.bodySmall)
            Spacer(Modifier.height(12.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = newName, onValueChange = { newName = it },
                    modifier = Modifier.weight(1f),
                    label = { Text("nový projekt") }, singleLine = true,
                )
                Spacer(Modifier.width(8.dp))
                Button(onClick = { onOpen(newName) }, enabled = newName.isNotBlank()) {
                    Text("Vytvořit")
                }
            }
            Spacer(Modifier.height(12.dp))
            projects.forEach { p ->
                ListItem(
                    headlineContent = { Text(p) },
                    leadingContent = { Icon(Icons.Filled.Folder, null) },
                    trailingContent = if (p == current) {
                        { Text("otevřeno", style = MaterialTheme.typography.labelSmall) }
                    } else null,
                    modifier = Modifier.clickable { onOpen(p) },
                )
            }
            if (current != null) {
                Spacer(Modifier.height(8.dp))
                TextButton(onClick = onClose) { Text("Zavřít projekt") }
            }
        }
    }
}
