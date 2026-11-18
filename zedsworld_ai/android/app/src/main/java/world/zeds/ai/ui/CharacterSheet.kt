package world.zeds.ai.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import world.zeds.ai.rp.Character

/** Seznam postav: vybrat, založit, upravit, smazat. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CharacterSheet(
    characters: List<Character>,
    active: Character?,
    onSelect: (Character) -> Unit,
    onEdit: (Character) -> Unit,
    onDelete: (Character) -> Unit,
    onNew: () -> Unit,
    onDismiss: () -> Unit,
) = ModalBottomSheet(onDismissRequest = onDismiss) {
    Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 24.dp)) {

        Text("Postavy", style = MaterialTheme.typography.titleMedium)
        Text(
            "Vybraná postava se vloží Zedovi do promptu – svět na ni pak reaguje podle toho, kdo je.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, bottom = 12.dp),
        )

        Button(onClick = onNew, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Filled.PersonAdd, null, Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Nová postava")
        }

        if (characters.isEmpty()) {
            Text(
                "Zatím žádná postava.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(vertical = 20.dp),
            )
        } else {
            LazyColumn(Modifier.heightIn(max = 380.dp).padding(top = 8.dp)) {
                items(characters, key = { it.id }) { c ->
                    ListItem(
                        headlineContent = { Text(c.name.ifBlank { "bez jména" }) },
                        supportingContent = if (c.role.isBlank()) null else {
                            { Text(c.role, maxLines = 1) }
                        },
                        leadingContent = {
                            RadioButton(selected = c.id == active?.id, onClick = { onSelect(c) })
                        },
                        trailingContent = {
                            Row {
                                IconButton(onClick = { onEdit(c) }) {
                                    Icon(Icons.Filled.Edit, "Upravit", Modifier.size(20.dp))
                                }
                                IconButton(onClick = { onDelete(c) }) {
                                    Icon(Icons.Filled.Delete, "Smazat", Modifier.size(20.dp))
                                }
                            }
                        },
                        modifier = Modifier.clickable { onSelect(c) },
                    )
                }
            }
        }
    }
}

/** Karta postavy. Vyplnit se dá ručně, nebo nechat vymyslet Zedovi. */
@Composable
fun CharacterEditor(
    initial: Character,
    drafting: Boolean,
    canDraft: Boolean,
    onDraft: (String) -> Unit,
    onSave: (Character) -> Unit,
    onDismiss: () -> Unit,
) {
    var c by remember(initial.id) { mutableStateOf(initial) }
    var brief by remember(initial.id) { mutableStateOf("") }

    // Co model vymyslí, přepíše rozepsanou kartu.
    LaunchedEffect(initial) { c = initial }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (initial.name.isBlank()) "Nová postava" else initial.name) },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = brief, onValueChange = { brief = it },
                        label = { Text("Ať ji vymyslí Zed") },
                        placeholder = { Text("např. stará lovkyně z Normalpolisu") },
                        singleLine = true, enabled = !drafting && canDraft,
                        modifier = Modifier.weight(1f),
                    )
                    Spacer(Modifier.width(8.dp))
                    if (drafting) {
                        CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
                    } else {
                        FilledIconButton(
                            onClick = { onDraft(brief) },
                            enabled = canDraft,
                        ) { Icon(Icons.Filled.AutoAwesome, "Vymyslet") }
                    }
                }
                if (!canDraft) {
                    Text(
                        "Vymýšlení postav potřebuje načtený model.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                HorizontalDivider(Modifier.padding(vertical = 4.dp))

                Field("Jméno", c.name) { c = c.copy(name = it) }
                Field("Role", c.role) { c = c.copy(role = it) }
                Field("Vzhled", c.appearance, lines = 2) { c = c.copy(appearance = it) }
                Field("Povaha", c.personality, lines = 2) { c = c.copy(personality = it) }
                Field("Mluva", c.speech, lines = 2) { c = c.copy(speech = it) }
                Field("Minulost", c.background, lines = 3) { c = c.copy(background = it) }
                Field("Cíl", c.goal, lines = 2) { c = c.copy(goal = it) }
                Field("Poznámky", c.notes, lines = 2) { c = c.copy(notes = it) }
            }
        },
        confirmButton = {
            TextButton(onClick = { onSave(c) }, enabled = !c.isBlank) { Text("Uložit") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Zrušit") } },
    )
}

@Composable
private fun Field(label: String, value: String, lines: Int = 1, onChange: (String) -> Unit) =
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = lines == 1,
        minLines = lines,
        modifier = Modifier.fillMaxWidth(),
    )
