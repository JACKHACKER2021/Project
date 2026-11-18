package world.zeds.ai.tools

/**
 * Nástroje dílny. Jeden seznam slouží dvěma stranám: uživateli jako
 * nabídka v aplikaci a modelu jako popis toho, co umí vyrobit – jinak
 * by se obojí rozešlo a Zed by nabízel, co aplikace neumí.
 */
enum class EngineTool(
    val title: String,
    val summary: String,
    /** Co se vloží do psaní, když na nástroj uživatel klepne. */
    val starter: String,
    /** Řádek do systémového promptu. */
    val forModel: String,
    /** Přípony, které z nástroje lezou. */
    val produces: String,
    /** Čím a kde se to doopravdy sestaví. */
    val builtWith: String,
    val ready: Boolean = true,
) {
    GODOT(
        "Godot Engine",
        "GDScript, scény a projekty.",
        "Založ Godot projekt: ",
        "Godot 4.3 – piš scény (.tscn) a GDScript (.gd). " +
            "Aplikace je uloží do projektu a umí ho vyexportovat jako ZIP " +
            "pro Godot Android editor, který z něj udělá APK.",
        produces = ".gd, .tscn, project.godot",
        builtWith = "Godot Android editor 4.2+ přímo v telefonu, " +
            "nebo Godot na počítači.",
    ),
    THREEJS(
        "Three.js",
        "3D scény a webové aplikace.",
        "Udělej three.js scénu: ",
        "Three.js – jeden soubor index.html s knihovnou z CDN. " +
            "Aplikace ho hned zobrazí v náhledu.",
        produces = ".html, .js",
        builtWith = "Nic se nekompiluje – běží v prohlížeči i v náhledu aplikace.",
    ),
    WEB(
        "HTML a SVG",
        "Stránky, rozhraní, obrázky kódem.",
        "Udělej stránku: ",
        "HTML, CSS a SVG – rovnou se zobrazí v náhledu a jdou vytisknout do PDF.",
        produces = ".html, .css, .svg, .pdf",
        builtWith = "Nic se nekompiluje – náhled v aplikaci, PDF přes tisk Androidu.",
    ),
    NATIVE(
        "Native C/C++",
        "Zdrojový kód knihoven; překlad na počítači.",
        "Napiš C++ pro: ",
        "C/C++ pro Android NDK – kód napiš celý, ale rovnou řekni, " +
            "že .so se musí přeložit na počítači; v telefonu NDK není.",
        produces = ".so, .c, .cpp, CMakeLists.txt",
        builtWith = "Linux s Android NDK (clang) a CMake nebo ndk-build – " +
            "na počítači. V telefonu zvládne jednoduché knihovny Termux " +
            "s balíčkem clang, ale pro knihovnu do APK je správná cesta NDK.",
    ),
    PYTHON(
        "Python",
        "Skripty a automatizace. Zatím jen kód, nespouští se.",
        "Napiš Python skript: ",
        "Python – kód se zatím jen ukládá, aplikace ho neumí spustit. " +
            "Nepiš, že ho uživatel může rovnou spustit v aplikaci.",
        produces = ".py",
        builtWith = "Nekompiluje se, ale spustit ho musí něco jiného: " +
            "Termux v telefonu, nebo Python na počítači. " +
            "Chaquopy přímo v aplikaci se teprve chystá.",
        ready = false,
    );

    companion object {
        /** Popis dílny pro systémový prompt. */
        fun forPrompt(): String = buildString {
            append("Nástroje, které aplikace má:\n")
            EngineTool.entries.forEach { t ->
                append("- ").append(t.title).append(" (").append(t.produces).append("): ")
                append(t.forModel)
                append(" Sestavuje se tak: ").append(t.builtWith).append("\n")
            }
            append("Nenabízej, co v seznamu není. Když je k sestavení potřeba ")
            append("něco mimo aplikaci – Godot editor, Termux, Linux s NDK – ")
            append("řekni to rovnou a neslibuj, že to aplikace udělá sama.")
        }
    }
}
