package world.zeds.ai.memory

/**
 * Rozseká dlouhý text na kousky do paměti. Řeže přednostně mezi
 * odstavci, až pak mezi větami – useknutá věta v půlce se v promptu
 * čte hrozně a model si ji domyslí špatně.
 */
object Chunker {

    private const val TARGET = 700     // znaků na kousek
    private const val MAX    = 1100

    fun chunk(text: String, source: String): List<Note> {
        val paragraphs = text
            .replace("\r\n", "\n")
            .split(Regex("\n{2,}"))
            .map { it.replace(Regex("[ \t]+"), " ").trim() }
            .filter { it.length > 20 }

        val pieces = mutableListOf<String>()
        val buf = StringBuilder()

        fun flush() {
            if (buf.isNotBlank()) pieces += buf.toString().trim()
            buf.setLength(0)
        }

        for (p in paragraphs) {
            if (p.length > MAX) {
                flush()
                pieces += splitSentences(p)
                continue
            }
            if (buf.length + p.length > TARGET) flush()
            if (buf.isNotEmpty()) buf.append("\n")
            buf.append(p)
        }
        flush()

        return pieces.mapIndexed { i, body ->
            Note(title = "$source · ${i + 1}", text = body, source = source)
        }
    }

    private fun splitSentences(p: String): List<String> {
        val out = mutableListOf<String>()
        val buf = StringBuilder()
        for (s in p.split(Regex("(?<=[.!?…])\\s+"))) {
            if (buf.length + s.length > TARGET && buf.isNotEmpty()) {
                out += buf.toString().trim(); buf.setLength(0)
            }
            if (buf.isNotEmpty()) buf.append(" ")
            buf.append(s)
        }
        if (buf.isNotBlank()) out += buf.toString().trim()
        return out
    }
}
