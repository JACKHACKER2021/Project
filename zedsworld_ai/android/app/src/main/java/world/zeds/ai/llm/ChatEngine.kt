package world.zeds.ai.llm

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.isActive

data class Msg(val role: String, val content: String) {
    companion object { const val USER = "user"; const val ASSISTANT = "assistant" }
}

/**
 * Staví ChatML prompt (formát Qwen) a streamuje odpověď.
 *
 * Prompt se skládá v Kotlinu, ne v C++ – chat šablona se u modelů liší
 * a tady se dá vyměnit bez rekompilace nativní části.
 */
class ChatEngine(private val bridge: LlamaBridge = LlamaBridge) {

    @Volatile var stopRequested = false
        private set

    fun requestStop() { stopRequested = true }

    fun buildPrompt(system: String, history: List<Msg>): String = buildString {
        append("<|im_start|>system\n").append(system).append("<|im_end|>\n")
        for (m in history) {
            append("<|im_start|>").append(m.role).append('\n')
                .append(m.content).append("<|im_end|>\n")
        }
        append("<|im_start|>assistant\n")
    }

    /**
     * Historii zkrátí tak, aby se prompt vešel do kontextu. Systémový prompt
     * a poslední zprávy mají přednost – staré se zahazují od začátku.
     */
    fun fitHistory(system: String, history: List<Msg>, nCtx: Int, reserveForReply: Int): List<Msg> {
        val budget = nCtx - reserveForReply - bridge.countTokens(system) - 16
        if (budget <= 0) return history.takeLast(1)
        val kept = ArrayDeque<Msg>()
        var used = 0
        for (m in history.asReversed()) {
            val cost = bridge.countTokens(m.content) + 8
            if (used + cost > budget && kept.isNotEmpty()) break
            kept.addFirst(m); used += cost
        }
        return kept.toList()
    }

    fun stream(
        system: String,
        history: List<Msg>,
        maxTokens: Int = 1024,
        temp: Float = 0.8f,
        nCtx: Int = 4096,
    ): Flow<String> = callbackFlow {
        stopRequested = false
        val fitted = fitHistory(system, history, nCtx, maxTokens)
        val prompt = buildPrompt(system, fitted)

        bridge.generate(prompt, maxTokens = maxTokens, temp = temp) { piece ->
            // Pozor: výsledek trySend se tu nesmí brát jako pokyn k zastavení.
            // Plná fronta znamená jen to, že obrazovka nestíhá překreslovat –
            // dřív se kvůli tomu generování utínalo uprostřed věty.
            trySend(piece)
            !stopRequested && isActive
        }
        close()
        awaitClose { stopRequested = true }
    }
        // Neomezená fronta: tokeny chodí rychleji, než je stihne vykreslit UI.
        .buffer(Channel.UNLIMITED, BufferOverflow.SUSPEND)
        .flowOn(Dispatchers.Default)
}
