package world.zeds.ai.rp

/**
 * Nechá model vyplnit kartu postavy. Záměrně se nepoužívá JSON –
 * malý model ho láme a jedna chybějící závorka shodí celou odpověď.
 * Štítkované řádky se dají rozebrat i z poloviční odpovědi.
 */
object CharacterWriter {

    private val FIELDS = listOf(
        "Jméno", "Role", "Vzhled", "Povaha", "Mluva", "Minulost", "Cíl",
    )

    fun prompt(brief: String): String = buildString {
        append("Vymysli postavu do Zeds World podle zadání: ")
        append(brief.trim().ifEmpty { "libovolná postava, která sedí do kánonu" })
        append("\n\nOdpověz přesně těmito řádky, nic dalšího nepiš:\n")
        FIELDS.forEach { append(it).append(": …\n") }
        append("\nJméno krátké, ostatní jednou dvěma větami. ")
        append("Drž se kánonu a tónu Zeds World.")
    }

    /** Rozebere odpověď modelu; co chybí, zůstane prázdné. */
    fun parse(reply: String): Character {
        val v = HashMap<String, String>()
        for (raw in reply.lineSequence()) {
            val line = raw.trim().removePrefix("-").removePrefix("*").trim()
            val label = FIELDS.firstOrNull {
                line.startsWith("$it:", true) || line.startsWith("**$it:**", true)
            } ?: continue
            v[label] = line
                .removePrefix("**").removePrefix(label).removePrefix("**")
                .trimStart(':', '*', ' ')
                .trim()
                .trim('…', '"')
                .trim()
        }
        return Character(
            name = v["Jméno"].orEmpty(),
            role = v["Role"].orEmpty(),
            appearance = v["Vzhled"].orEmpty(),
            personality = v["Povaha"].orEmpty(),
            speech = v["Mluva"].orEmpty(),
            background = v["Minulost"].orEmpty(),
            goal = v["Cíl"].orEmpty(),
        )
    }
}
