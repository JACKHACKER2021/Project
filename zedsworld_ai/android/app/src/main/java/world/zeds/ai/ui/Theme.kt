package world.zeds.ai.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val Rust   = Color(0xFFB4541E)   // rez a měď – Normalpolis
private val Copper = Color(0xFFCE8A4E)
private val Ash    = Color(0xFF14110F)

private val Dark = darkColorScheme(
    primary = Copper, onPrimary = Ash,
    secondary = Rust, background = Ash,
    surface = Color(0xFF1E1A17), onSurface = Color(0xFFEDE4DA),
)

private val Light = lightColorScheme(
    primary = Rust, secondary = Copper,
    background = Color(0xFFFAF6F2), surface = Color(0xFFFFFFFF),
)

@Composable
fun ZedTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = if (isSystemInDarkTheme()) Dark else Light, content = content)
