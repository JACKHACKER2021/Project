package world.zeds.ai.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import world.zeds.ai.llm.Msg

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(vm: ZedViewModel) {
    val s by vm.state.collectAsState()
    var input by remember { mutableStateOf("") }
    var pdfQuestion by remember { mutableStateOf("") }
    var showProjects by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    val pickPdf = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let {
            vm.importPdf(it, it.lastPathSegment?.substringAfterLast('/') ?: "dokument.pdf",
                pdfQuestion)
            pdfQuestion = ""
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
                        Text(s.project?.let { "dílna · $it" } ?: s.status,
                            style = MaterialTheme.typography.labelSmall)
                    }
                },
                actions = {
                    IconToggleButton(checked = s.roleplay, onCheckedChange = { vm.toggleRoleplay() }) {
                        Icon(Icons.Filled.TheaterComedy,
                            contentDescription = if (s.roleplay) "RP zapnuto" else "RP vypnuto")
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
                        item { EmptyHint(s.roleplay, s.project != null) }
                    }
                    items(s.messages) { Bubble(it.role, it.content) }
                    if (s.partial.isNotEmpty()) item { Bubble(Msg.ASSISTANT, s.partial) }
                    if (s.savedFiles.isNotEmpty()) item {
                        SavedFiles(s.savedFiles, onOpen = vm::showPreview)
                    }
                }
            }
        }
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
            Text("Stahování lze přerušit a pokračovat později.",
                style = MaterialTheme.typography.labelSmall)
        }
        s.loading -> { CircularProgressIndicator(); Spacer(Modifier.height(10.dp)); Text(s.status) }
        else -> {
            Button(onClick = onStart) { Text("Připravit model") }
            Spacer(Modifier.height(10.dp))
            Text(s.status, style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
private fun EmptyHint(rp: Boolean, workshop: Boolean) = Card(Modifier.fillMaxWidth()) {
    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(if (rp) "Režim roleplay" else "Zed", style = MaterialTheme.typography.titleSmall)
        Text(
            when {
                rp -> "Napiš, kým jsi a kde jsi. Zed povede scénu a bude hrát za svět."
                workshop -> "Dílna je otevřená. Řekni, co postavit — HTML, three.js, GDScript, SVG. " +
                        "Soubory se uloží do projektu a HTML se hned zobrazí."
                else -> "Zeptej se na lore, nech si napsat příběh, vytvoř postavu, " +
                        "nebo otevři dílnu a nech ho psát kód. PDF přilož sponkou."
            },
            style = MaterialTheme.typography.bodySmall,
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
) = Surface(tonalElevation = 3.dp) {
    Row(
        Modifier.fillMaxWidth().padding(8.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        IconButton(onClick = onPdf, enabled = !streaming) {
            Icon(Icons.Filled.AttachFile, contentDescription = "Přiložit PDF")
        }
        OutlinedTextField(
            value = value, onValueChange = onValue,
            modifier = Modifier.weight(1f),
            placeholder = { Text("Napiš Zedovi…") },
            maxLines = 5,
        )
        Spacer(Modifier.width(6.dp))
        FilledIconButton(onClick = if (streaming) onStop else onSend,
            enabled = streaming || value.isNotBlank()) {
            Icon(if (streaming) Icons.Filled.Stop else Icons.Filled.Send,
                contentDescription = if (streaming) "Zastavit" else "Poslat")
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
