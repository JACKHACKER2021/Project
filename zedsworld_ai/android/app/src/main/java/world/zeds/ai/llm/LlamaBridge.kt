package world.zeds.ai.llm

/** Tenký most na llama.cpp. Všechny metody jsou blokující – volat z Dispatchers.Default. */
object LlamaBridge {

    init { System.loadLibrary("zedllm") }

    /** Callback pro streamování. Vrať false pro zastavení generování. */
    fun interface TokenSink { fun onToken(piece: String): Boolean }

    @Volatile private var handle: Long = 0L
    val isLoaded: Boolean get() = handle != 0L

    private external fun nativeBackendInit()
    private external fun nativeLoad(path: String, nCtx: Int, nThreads: Int): Long
    private external fun nativeFree(handle: Long)
    private external fun nativeResetContext(handle: Long)
    private external fun nativeCountTokens(handle: Long, text: String): Int
    private external fun nativeGenerate(
        handle: Long, prompt: String, maxTokens: Int,
        temp: Float, topP: Float, topK: Int, repeatPenalty: Float,
        seed: Int, callback: TokenSink,
    )

    private var backendReady = false

    @Synchronized
    fun load(modelPath: String, nCtx: Int = 4096, nThreads: Int = defaultThreads()): Boolean {
        if (!backendReady) { nativeBackendInit(); backendReady = true }
        unload()
        handle = nativeLoad(modelPath, nCtx, nThreads)
        return isLoaded
    }

    @Synchronized
    fun unload() {
        if (handle != 0L) { nativeFree(handle); handle = 0L }
    }

    fun resetContext() { if (handle != 0L) nativeResetContext(handle) }

    fun countTokens(text: String): Int = if (handle == 0L) 0 else nativeCountTokens(handle, text)

    fun generate(
        prompt: String,
        maxTokens: Int = 1024,
        temp: Float = 0.8f,
        topP: Float = 0.9f,
        topK: Int = 40,
        repeatPenalty: Float = 1.1f,
        seed: Int = (System.nanoTime() and 0x7FFFFFFF).toInt(),
        sink: TokenSink,
    ) {
        check(handle != 0L) { "model není načtený" }
        nativeGenerate(handle, prompt, maxTokens, temp, topP, topK, repeatPenalty, seed, sink)
    }

    /** Víc vláken než fyzických jader výkon nezvedne, jen vybije baterii. */
    private fun defaultThreads(): Int =
        (Runtime.getRuntime().availableProcessors() / 2).coerceIn(2, 6)
}
