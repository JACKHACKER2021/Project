package world.zeds.ai.tools

import world.zeds.ai.workspace.Project
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * Připraví z projektu v dílně platný Godot 4.3 projekt a zabalí ho do ZIPu.
 *
 * APK z toho NEsestaví tato aplikace ani model – sestaví ho Godot.
 * Na telefonu to zvládne Godot Android editor (4.2+): otevřít projekt,
 * Project → Export → Android.
 */
object GodotProject {

    fun scaffold(project: Project, gameName: String = project.name) {
        if (project.read("project.godot") == null) {
            project.write("project.godot", """
                ; Godot 4.3 project – vygenerováno aplikací Zed
                config_version=5

                [application]
                config/name="$gameName"
                run/main_scene="res://main.tscn"
                config/features=PackedStringArray("4.3", "GL Compatibility")

                [rendering]
                renderer/rendering_method="gl_compatibility"
                renderer/rendering_method.mobile="gl_compatibility"

                [display]
                window/size/viewport_width=1280
                window/size/viewport_height=720
                window/handheld/orientation=1
            """.trimIndent())
        }
        if (project.read("main.tscn") == null) {
            project.write("main.tscn", """
                [gd_scene load_steps=2 format=3]

                [ext_resource type="Script" path="res://scripts/game.gd" id="1"]

                [node name="Main" type="Node3D"]
                script = ExtResource("1")
            """.trimIndent())
        }
        if (project.read("scripts/game.gd") == null) {
            project.write("scripts/game.gd", """
                extends Node3D

                func _ready() -> void:
                	print("Zeds World – projekt připraven")
            """.trimIndent())
        }
        project.write("export_presets.cfg", """
            [preset.0]
            name="Android"
            platform="Android"
            runnable=true
            export_filter="all_resources"
            export_path="export/${gameName.replace(' ', '-')}.apk"

            [preset.0.options]
            gradle_build/use_gradle_build=false
            package/unique_name="world.zeds.${gameName.lowercase().replace(Regex("[^a-z0-9]"), "")}"
            package/name="$gameName"
            architectures/arm64-v8a=true
            architectures/armeabi-v7a=false
        """.trimIndent())
    }

    /** Zabalí projekt do ZIPu, který jde otevřít v Godot Android editoru. */
    fun zip(project: Project, outFile: File): File {
        scaffold(project)
        outFile.parentFile?.mkdirs()
        ZipOutputStream(FileOutputStream(outFile)).use { zos ->
            for (f in project.files()) {
                val rel = f.relativeTo(project.dir).path
                zos.putNextEntry(ZipEntry(rel))
                f.inputStream().use { it.copyTo(zos) }
                zos.closeEntry()
            }
        }
        return outFile
    }
}
