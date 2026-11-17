package world.zeds.ai.llm

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Model se nestahuje do APK (2,5 GB, Play limit 150 MB), ale při prvním
 * spuštění do interního úložiště. Stahování pokračuje po přerušení (Range).
 */
class ModelRepository(private val ctx: Context) {

    data class Progress(val bytes: Long, val total: Long, val done: Boolean = false) {
        val percent: Int get() = if (total > 0) ((bytes * 100) / total).toInt() else 0
    }

    val modelFile: File get() = File(ctx.filesDir, "models/$FILENAME")

    fun isReady(): Boolean = modelFile.exists() && modelFile.length() > MIN_BYTES

    /** Je model přibalený v APK (assets/zed-4b-q4_k_m.gguf)? */
    fun isBundled(): Boolean = runCatching {
        ctx.assets.list("")?.contains(FILENAME) == true
    }.getOrDefault(false)

    /**
     * Rozbalí model z APK do interního úložiště.
     *
     * llama.cpp potřebuje běžný soubor na disku – asset v APK se mmapovat
     * nedá, protože leží uvnitř archivu na offsetu a llama_model_load_from_file
     * umí jen cestu. Proto ta jednorázová kopie.
     */
    fun installFromAssets(): Flow<Progress> = flow {
        val target = modelFile
        target.parentFile?.mkdirs()
        val part = File(target.parentFile, "$FILENAME.part")
        part.delete()

        val total = ctx.assets.openFd(FILENAME).use { it.length }
        emit(Progress(0, total))

        ctx.assets.open(FILENAME, android.content.res.AssetManager.ACCESS_STREAMING).use { input ->
            java.io.FileOutputStream(part).use { out ->
                val buf = ByteArray(1 shl 20)
                var written = 0L
                var lastEmit = 0L
                while (true) {
                    val n = input.read(buf)
                    if (n < 0) break
                    out.write(buf, 0, n)
                    written += n
                    val now = System.currentTimeMillis()
                    if (now - lastEmit > 150) { emit(Progress(written, total)); lastEmit = now }
                }
            }
        }
        if (!part.renameTo(target)) throw IllegalStateException("nelze dokončit soubor modelu")
        emit(Progress(target.length(), target.length(), done = true))
    }.flowOn(Dispatchers.IO)

    fun download(url: String = DEFAULT_URL): Flow<Progress> = flow {
        val target = modelFile
        target.parentFile?.mkdirs()
        val part = File(target.parentFile, "$FILENAME.part")

        var from = if (part.exists()) part.length() else 0L
        var conn = open(url, from)

        // Server nepodporuje Range – stáhnout znovu od začátku
        if (from > 0 && conn.responseCode != HttpURLConnection.HTTP_PARTIAL) {
            conn.disconnect(); part.delete(); from = 0; conn = open(url, 0)
        }
        if (conn.responseCode !in 200..299) {
            throw IllegalStateException("stahování selhalo: HTTP ${conn.responseCode}")
        }

        val total = from + conn.contentLengthLong.coerceAtLeast(0)
        emit(Progress(from, total))

        conn.inputStream.use { input ->
            java.io.FileOutputStream(part, from > 0).use { out ->
                val buf = ByteArray(1 shl 16)
                var written = from
                var lastEmit = 0L
                while (true) {
                    val n = input.read(buf)
                    if (n < 0) break
                    out.write(buf, 0, n)
                    written += n
                    // Emitovat max 10× za sekundu, jinak zahltí UI
                    val now = System.currentTimeMillis()
                    if (now - lastEmit > 100) { emit(Progress(written, total)); lastEmit = now }
                }
            }
        }
        conn.disconnect()

        if (!part.renameTo(target)) throw IllegalStateException("nelze dokončit soubor modelu")
        emit(Progress(target.length(), target.length(), done = true))
    }.flowOn(Dispatchers.IO)

    private fun open(url: String, from: Long): HttpURLConnection =
        (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 30_000
            readTimeout    = 60_000
            instanceFollowRedirects = true
            if (from > 0) setRequestProperty("Range", "bytes=$from-")
        }

    companion object {
        const val FILENAME = "zed-4b-q4_k_m.gguf"
        private const val MIN_BYTES = 500L * 1024 * 1024

        /**
         * Sem patří URL natrénovaného modelu z Colabu (fáze 2–3).
         * Do té doby ukazuje na základní Qwen3 4B, takže aplikace jde
         * vyzkoušet ještě před prvním fine-tunem.
         */
        const val DEFAULT_URL =
            "https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen3-4B-Instruct-2507-Q4_K_M.gguf"
    }
}
