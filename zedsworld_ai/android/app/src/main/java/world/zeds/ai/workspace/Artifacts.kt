package world.zeds.ai.workspace

/**
 * Z odpovědi modelu vytáhne bloky kódu a uloží je do projektu.
 *
 * Očekávaný formát (viz SystemPrompts.WORKSHOP):
 *   ```html index.html
 *   ...obsah...
 *   ```
 */
object Artifacts {

    data class Block(val lang: String, val path: String, val content: String)

    private val FENCE = Regex(
        """```[ \t]*([A-Za-z0-9+#._-]+)?[ \t]*([^\n`]*)?\n(.*?)```""",
        setOf(RegexOption.DOT_MATCHES_ALL)
    )

    private val DEFAULT_NAME = mapOf(
        "html" to "index.html", "svg" to "obrazek.svg", "javascript" to "script.js",
        "js" to "script.js", "gdscript" to "script.gd", "gd" to "script.gd",
        "python" to "script.py", "py" to "script.py", "json" to "data.json",
        "markdown" to "dokument.md", "md" to "dokument.md", "css" to "style.css",
    )

    fun parse(reply: String): List<Block> = FENCE.findAll(reply).mapNotNull { m ->
        val lang = (m.groupValues[1].ifBlank { "" }).lowercase()
        val hint = m.groupValues[2].trim()
        val body = m.groupValues[3]
        if (body.isBlank()) return@mapNotNull null

        // Název souboru je buď za jazykem, nebo se odvodí z jazyka
        val path = when {
            hint.contains('.') && !hint.contains(' ') -> hint
            else -> DEFAULT_NAME[lang] ?: return@mapNotNull null
        }
        Block(lang, path, body.trimEnd())
    }.toList()

    /** Uloží všechny bloky z odpovědi; vrací zapsané cesty. */
    fun saveAll(project: Project, reply: String): List<String> =
        parse(reply).map { project.write(it.path, it.content).relativeTo(project.dir).path }
}
