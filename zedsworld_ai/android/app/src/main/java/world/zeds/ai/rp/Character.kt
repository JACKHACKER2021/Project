package world.zeds.ai.rp

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * RP postava. Pole jsou volná – prázdné se do promptu nedostanou,
 * takže postava může být i jen jméno a dvě věty.
 */
data class Character(
    val id: String = System.currentTimeMillis().toString(),
    val name: String = "",
    val role: String = "",          // čím je: lovec, hybrid, stroj…
    val appearance: String = "",
    val personality: String = "",
    val speech: String = "",        // jak mluví
    val background: String = "",
    val goal: String = "",
    val notes: String = "",
) {
    val isBlank: Boolean get() = name.isBlank() && role.isBlank() && background.isBlank()

    /** Blok do systémového promptu. Vynechá, co uživatel nevyplnil. */
    fun asPrompt(): String = buildString {
        append("Hráč hraje postavu ").append(name.ifBlank { "beze jména" })
        if (role.isNotBlank()) append(" (").append(role).append(")")
        append(".\n")
        fun line(label: String, v: String) {
            if (v.isNotBlank()) append("- ").append(label).append(": ").append(v.trim()).append("\n")
        }
        line("Vzhled", appearance)
        line("Povaha", personality)
        line("Mluva", speech)
        line("Minulost", background)
        line("Cíl", goal)
        line("Poznámky", notes)
        append("Tuhle postavu hraje hráč – nerozhoduj za ni a nepopisuj, co si myslí. ")
        append("Svět na ni ale reaguje podle toho, kdo je.")
    }.trim()

    fun toJson(): String = JSONObject().apply {
        put("id", id); put("name", name); put("role", role)
        put("appearance", appearance); put("personality", personality)
        put("speech", speech); put("background", background)
        put("goal", goal); put("notes", notes)
    }.toString(2)

    companion object {
        fun fromJson(s: String): Character = JSONObject(s).run {
            Character(
                id = optString("id", System.currentTimeMillis().toString()),
                name = optString("name"), role = optString("role"),
                appearance = optString("appearance"), personality = optString("personality"),
                speech = optString("speech"), background = optString("background"),
                goal = optString("goal"), notes = optString("notes"),
            )
        }
    }
}

/** Postavy jako JSON soubory ve filesDir/characters. */
class CharacterStore(ctx: Context) {

    private val dir = File(ctx.filesDir, "characters").apply { mkdirs() }

    fun all(): List<Character> =
        dir.listFiles { f -> f.extension == "json" }
            ?.sortedByDescending { it.lastModified() }
            ?.mapNotNull { runCatching { Character.fromJson(it.readText()) }.getOrNull() }
            ?: emptyList()

    fun save(c: Character): Character {
        File(dir, "${c.id}.json").writeText(c.toJson())
        return c
    }

    fun delete(c: Character) { File(dir, "${c.id}.json").delete() }
}
