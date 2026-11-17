package world.zeds.ai.ui

import android.annotation.SuppressLint
import android.webkit.WebView
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView

/** Náhled HTML / three.js / SVG z dílny. */
@SuppressLint("SetJavaScriptEnabled")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PreviewSheet(html: String, onClose: () -> Unit) = Scaffold(
    topBar = {
        TopAppBar(
            title = { Text("Náhled") },
            navigationIcon = {
                IconButton(onClick = onClose) { Icon(Icons.Filled.Close, "Zavřít") }
            },
        )
    },
) { pad ->
    AndroidView(
        modifier = Modifier.padding(pad).fillMaxSize(),
        factory = { ctx ->
            WebView(ctx).apply {
                settings.javaScriptEnabled = true          // three.js potřebuje JS
                settings.domStorageEnabled = true
                settings.allowFileAccess = false           // generovaný kód nesmí na disk
                settings.allowContentAccess = false
            }
        },
        update = { it.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null) },
    )
}
