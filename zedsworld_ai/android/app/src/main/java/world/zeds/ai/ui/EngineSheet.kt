package world.zeds.ai.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import world.zeds.ai.tools.EngineTool

/** Dílna: co umí Zed vyrobit. Stejný seznam zná i model. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EngineSheet(
    project: String?,
    onPick: (EngineTool) -> Unit,
    onExportGodot: () -> Unit,
    onDismiss: () -> Unit,
) = ModalBottomSheet(onDismissRequest = onDismiss) {
    Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 24.dp)) {

        Text("Dílna", style = MaterialTheme.typography.titleMedium)
        Text(
            project?.let { "otevřený projekt · $it" }
                ?: "Otevři projekt ve složce, aby se soubory ukládaly.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, bottom = 8.dp),
        )

        EngineTool.entries.forEach { tool ->
            ListItem(
                headlineContent = { Text(tool.title) },
                supportingContent = {
                    Column {
                        Text(tool.summary)
                        Text(
                            tool.produces + " · " + tool.builtWith,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                },
                leadingContent = {
                    Icon(
                        when (tool) {
                            EngineTool.GODOT -> Icons.Filled.SportsEsports
                            EngineTool.THREEJS -> Icons.Filled.ViewInAr
                            EngineTool.WEB -> Icons.Filled.Language
                            EngineTool.NATIVE -> Icons.Filled.Memory
                            EngineTool.PYTHON -> Icons.Filled.Terminal
                        },
                        null,
                    )
                },
                trailingContent = if (tool.ready) null else {
                    { Text("brzy", style = MaterialTheme.typography.labelSmall) }
                },
                modifier = Modifier.clickable { onPick(tool) },
            )
        }

        if (project != null) {
            HorizontalDivider(Modifier.padding(vertical = 8.dp))
            OutlinedButton(onClick = onExportGodot, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.Archive, null, Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Vyexportovat projekt jako ZIP")
            }
            Text(
                "ZIP otevři v Godot Android editoru (4.2+) – ten z něj udělá APK.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 6.dp),
            )
        }
    }
}
