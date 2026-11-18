package world.zeds.ai.memory

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.Normalizer

/** Jeden kousek paměti – ručně napsaná poznámka nebo úryvek z PDF. */
data class Note(
    val id: String = System.currentTimeMillis().toString() + "-" + (0..999).random(),
    val title: String = "",
    val text: String = "",
    val source: String = "",      // prázdné = ruční poznámka, jinak název PDF
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id); put("title", title); put("text", text); put("source", source)
    }

    companion object {
        fun fromJson(o: JSONObject) = Note(
            id = o.optString("id"), title = o.optString("title"),
            text = o.optString("text"), source = o.optString("source"),
        )
    }
}

/**
 * Paměť lore. Celá se drží v jednom JSON souboru – poznámek jsou
 * stovky, ne statisíce, takže databáze by byla zbytečná váha.
 *
 * Do promptu se nedává všechno, ale jen to, co se k dotazu hodí:
 * kontext modelu je 4096 tokenů a nacpat tam celou paměť by vytlačilo
 * samotnou konverzaci.
 */
class MemoryStore(ctx: Context) {

    private val file = File(ctx.filesDir, "memory.json")
    private var cache: MutableList<Note>? = null

    @Synchronized
    fun all(): List<Note> {
        cache?.let { return it }
        val list = mutableListOf<Note>()
        if (file.exists()) runCatching {
            val arr = JSONArray(file.readText())
            for (i in 0 until arr.length()) list += Note.fromJson(arr.getJSONObject(i))
        }
        cache = list
        return list
    }

    @Synchronized
    private fun persist(list: MutableList<Note>) {
        cache = list
        file.writeText(JSONArray().apply { list.forEach { put(it.toJson()) } }.toString())
    }

    @Synchronized
    fun add(notes: List<Note>) = persist((all().toMutableList()).also { it.addAll(notes) })

    @Synchronized
    fun save(n: Note) = persist(all().toMutableList().also { list ->
        val i = list.indexOfFirst { it.id == n.id }
        if (i >= 0) list[i] = n else list += n
    })

    @Synchronized
    fun delete(n: Note) = persist(all().toMutableList().also { l -> l.removeAll { it.id == n.id } })

    @Synchronized
    fun deleteSource(source: String) =
        persist(all().toMutableList().also { l -> l.removeAll { it.source == source } })

    fun sources(): List<String> = all().map { it.source }.filter { it.isNotBlank() }.distinct()

    // ───────────────────────────── vyhledání k dotazu

    /**
     * Vybere poznámky, které se k dotazu hodí, do zadaného rozpočtu znaků.
     * Čeština skloňuje, takže se neporovnávají celá slova, ale jejich
     * začátky – "Zédovského" tak najde poznámku o "Zédovský".
     */
    fun recall(query: String, budgetChars: Int = 2400): List<Note> {
        val notes = all()
        if (notes.isEmpty()) return emptyList()

        val stems = stems(query)
        if (stems.isEmpty()) return emptyList()

        val scored = notes.mapNotNull { n ->
            val hay = fold(n.title + " " + n.text)
            val hits = stems.count { hay.contains(it) }
            if (hits == 0) null else {
                // Shoda v názvu váží víc než kdekoliv v těle.
                val titleHits = stems.count { fold(n.title).contains(it) }
                n to (hits + titleHits)
            }
        }.sortedByDescending { it.second }

        val out = mutableListOf<Note>()
        var used = 0
        for ((n, _) in scored) {
            val cost = n.title.length + n.text.length + 8
            if (used + cost > budgetChars) continue
            out += n
            used += cost
        }
        return out
    }

    /** Blok s fakty do systémového promptu, nebo null když není co dodat. */
    fun recallPrompt(query: String, budgetChars: Int = 2400): String? {
        val hits = recall(query, budgetChars)
        if (hits.isEmpty()) return null
        return buildString {
            append("Z paměti o Zeds World – ber to jako kánon, ")
            append("i kdyby to odporovalo tomu, co si myslíš:\n")
            hits.forEach { n ->
                append("- ")
                if (n.title.isNotBlank()) append(n.title).append(": ")
                append(n.text.trim()).append("\n")
            }
            append("Co v paměti není, si nevymýšlej jako fakt.")
        }
    }

    private fun stems(q: String): List<String> =
        fold(q).split(Regex("[^\\p{L}\\p{N}]+"))
            .filter { it.length >= 4 }
            .map { it.take(5) }
            .distinct()

    /** Malá písmena bez diakritiky – "Zéd" a "zed" musí sedět na sebe. */
    private fun fold(s: String): String =
        Normalizer.normalize(s.lowercase(), Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
}
