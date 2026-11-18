package world.zeds.ai.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import world.zeds.ai.memory.Note

/**
 * Paměť lore. Co je tady, Zed bere jako kánon – k dotazu se vždycky
 * vytáhne jen to, co se hodí, aby se do kontextu vešla i konverzace.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemorySheet(
    notes: List<Note>,
    onEdit: (Note) -> Unit,
    onDelete: (Note) -> Unit,
    onForgetSource: (String) -> Unit,
    onNew: () -> Unit,
    onImportPdf: () -> Unit,
    onDismiss: () -> Unit,
) = ModalBottomSheet(onDismissRequest = onDismiss) {
    Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 24.dp)) {

        Text("Paměť", style = MaterialTheme.typography.titleMedium)
        Text(
            if (notes.isEmpty()) "Zatím prázdná."
            else "${notes.size} poznámek. Zed si z nich ke každé otázce " +
                 "vytáhne to, co se hodí, a bere je jako kánon.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, bottom = 12.dp),
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = onNew, modifier = Modifier.weight(1f)) {
                Icon(Icons.Filled.Add, null, Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Poznámka")
            }
            OutlinedButton(onClick = onImportPdf, modifier = Modifier.weight(1f)) {
                Icon(Icons.Filled.PictureAsPdf, null, Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Z PDF")
            }
        }

        // Poznámky z jednoho PDF se dají zapomenout najednou.
        val sources = notes.map { it.source }.filter { it.isNotBlank() }.distinct()
        if (sources.isNotEmpty()) {
            Column(Modifier.padding(top = 12.dp)) {
                Text("Dokumenty", style = MaterialTheme.typography.labelMedium)
                sources.forEach { src ->
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 2.dp),
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                    ) {
                        Text(
                            "$src · ${notes.count { it.source == src }}",
                            style = MaterialTheme.typography.bodySmall,
                            maxLines = 1, overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f),
                        )
                        TextButton(onClick = { onForgetSource(src) }) { Text("Zapomenout") }
                    }
                }
            }
        }

        if (notes.isNotEmpty()) {
            HorizontalDivider(Modifier.padding(vertical = 8.dp))
            LazyColumn(Modifier.heightIn(max = 340.dp)) {
                items(notes, key = { it.id }) { n ->
                    ListItem(
                        headlineContent = {
                            Text(
                                n.title.ifBlank { n.text.take(40) },
                                maxLines = 1, overflow = TextOverflow.Ellipsis,
                            )
                        },
                        supportingContent = {
                            Text(n.text, maxLines = 2, overflow = TextOverflow.Ellipsis)
                        },
                        trailingContent = {
                            IconButton(onClick = { onDelete(n) }) {
                                Icon(Icons.Filled.Delete, "Smazat", Modifier.size(20.dp))
                            }
                        },
                        modifier = Modifier.clickable { onEdit(n) },
                    )
                }
            }
        }
    }
}

/** Ruční poznámka. Název je nepovinný, ale pomáhá ji najít. */
@Composable
fun NoteEditor(initial: Note, onSave: (Note) -> Unit, onDismiss: () -> Unit) {
    var n by remember(initial.id) { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (initial.text.isBlank()) "Nová poznámka" else "Poznámka") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = n.title, onValueChange = { n = n.copy(title = it) },
                    label = { Text("Čeho se týká") },
                    placeholder = { Text("např. Jackov") },
                    singleLine = true, modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = n.text, onValueChange = { n = n.copy(text = it) },
                    label = { Text("Fakt") },
                    minLines = 4, modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { onSave(n) }, enabled = n.text.isNotBlank()) { Text("Uložit") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Zrušit") } },
    )
}
