package world.zeds.ai.tools

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

/**
 * Co je v telefonu doopravdy k dispozici. Bez tohohle by model hádal
 * a sliboval sestavení, které nemá čím provést.
 */
data class Tool(
    val key: String,
    val label: String,
    val installed: Boolean,
    /** Co s ním jde dělat, když je. */
    val gives: String,
    /** Kde se bere, když není. */
    val howToGet: String,
)

object Toolchain {

    // Godot Android editor se jmenuje jinak podle hlavní verze.
    private val GODOT = listOf(
        "org.godotengine.editor.v4",
        "org.godotengine.editor.v4.debug",
        "org.godotengine.editor.v3",
    )
    private const val TERMUX = "com.termux"

    fun detect(ctx: Context): List<Tool> {
        val pm = ctx.packageManager
        fun has(pkg: String) = runCatching {
            pm.getPackageInfo(pkg, 0); true
        }.getOrDefault(false)

        val godot = GODOT.any { has(it) }
        val termux = has(TERMUX)
        val browser = runCatching {
            pm.resolveActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com")),
                PackageManager.MATCH_DEFAULT_ONLY,
            ) != null
        }.getOrDefault(false)

        return listOf(
            Tool(
                "godot", "Godot Android editor", godot,
                "otevře projekt, ověří scény a skripty, vyexportuje APK",
                "Google Play nebo godotengine.org – verze 4.2 a vyšší",
            ),
            Tool(
                "termux", "Termux", termux,
                "spustí Python a shell; s balíčkem clang i jednoduché nativní knihovny",
                "F-Droid nebo github.com/termux/termux-app (verze z Google Play je zastaralá)",
            ),
            Tool(
                "browser", "Prohlížeč", browser,
                "spustí HTML, SVG a three.js mimo aplikaci",
                "jakýkoli prohlížeč",
            ),
        )
    }

    /**
     * Popis prostředí do systémového promptu. Záměrně vyjmenovává i to,
     * co v telefonu principiálně být nemůže – jinak model nabízí, že
     * aplikace něco sestaví sama.
     */
    fun forPrompt(ctx: Context): String = buildString {
        append("Prostředí tohohle telefonu:\n")
        detect(ctx).forEach { t ->
            append("- ").append(t.label).append(": ")
            if (t.installed) append("je nainstalovaný – ").append(t.gives)
            else append("NENÍ nainstalovaný (").append(t.howToGet).append(")")
            append("\n")
        }
        append("- Android SDK, NDK, Gradle a JDK: v telefonu nejsou a nainstalovat nejdou. ")
        append("Překlad .so a stavění APK Gradlem se dělá na Linuxu na počítači.\n")
        append("- Sama aplikace nic nekompiluje a nespouští žádné příkazy.\n")
        append("Nikdy netvrď, že APK, .so nebo cokoliv jiného bylo sestaveno – ")
        append("ty soubory nevidíš. Řekni, co je hotové jako zdroják, ")
        append("čím se to sestaví a co k tomu chybí.")
    }
}
