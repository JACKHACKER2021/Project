package world.zeds.ai.workspace

import android.content.Context
import java.io.File

/** Projekt = adresář v dílně. Soubory, které model vygeneruje, končí tady. */
class Workspace(ctx: Context) {

    private val root = File(ctx.filesDir, "projects").apply { mkdirs() }

    fun projects(): List<Project> =
        root.listFiles { f -> f.isDirectory }
            ?.sortedByDescending { it.lastModified() }
            ?.map { Project(it) } ?: emptyList()

    fun create(name: String): Project {
        val safe = name.trim().ifEmpty { "projekt" }
            .replace(Regex("[^\\p{L}\\p{N} _.-]"), "_").take(60)
        var dir = File(root, safe)
        var i = 2
        while (dir.exists()) { dir = File(root, "$safe $i"); i++ }
        dir.mkdirs()
        return Project(dir)
    }

    fun delete(p: Project) = p.dir.deleteRecursively()
}

class Project(val dir: File) {
    val name: String get() = dir.name

    fun files(): List<File> =
        dir.walkTopDown().filter { it.isFile }.sortedBy { it.path }.toList()

    /** Zapíše soubor, včetně podadresářů. Cesta se drží v projektu. */
    fun write(relativePath: String, content: String): File {
        val clean = relativePath.trim().trimStart('/')
            .split('/').filter { it.isNotBlank() && it != ".." }.joinToString("/")
            .ifEmpty { "soubor.txt" }
        val f = File(dir, clean)
        f.parentFile?.mkdirs()
        f.writeText(content)
        dir.setLastModified(System.currentTimeMillis())
        return f
    }

    fun read(relativePath: String): String? =
        File(dir, relativePath).takeIf { it.isFile }?.readText()

    /** Vstupní HTML pro náhled, pokud projekt nějaké má. */
    fun entryHtml(): File? =
        File(dir, "index.html").takeIf { it.isFile }
            ?: files().firstOrNull { it.extension.equals("html", true) }
}
