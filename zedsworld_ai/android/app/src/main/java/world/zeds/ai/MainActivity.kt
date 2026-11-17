package world.zeds.ai

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import world.zeds.ai.ui.ChatScreen
import world.zeds.ai.ui.ZedTheme
import world.zeds.ai.ui.ZedViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ZedTheme {
                val vm: ZedViewModel = viewModel()
                ChatScreen(vm)
            }
        }
    }
}
