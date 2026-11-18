// JNI most mezi Kotlinem a llama.cpp.
//
// Pozor: llama.cpp mění API často. Tento soubor je psaný proti tagu b4585
// (viz CMakeLists.txt). Při aktualizaci zkontroluj hlavně llama_sampler_*,
// llama_vocab_*, llama_memory_* a llama_sampler_init_penalties.

#include <jni.h>
#include <android/log.h>
#include <string>
#include <vector>
#include "llama.h"

#define TAG "zedllm"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

struct ZedCtx {
    llama_model   *model = nullptr;
    llama_context *ctx   = nullptr;
    /** Tokeny, které už v kontextu leží – díky nim se prompt nepočítá znovu. */
    std::vector<llama_token> cached;
};

/**
 * Délka nejdelšího celého UTF-8 na začátku. Model umí poslat víceznakový
 * znak po částech – "ě" přijde na dvakrát – a nedodělaný znak by při
 * předání do Javy shodil celou aplikaci.
 */
static size_t utf8_complete_len(const std::string &s) {
    size_t i = s.size();
    // Nejvýš tři bajty zpátky; delší sekvence UTF-8 nemá.
    for (size_t back = 0; back < 4 && back < s.size(); back++) {
        const size_t at = i - back - 1;
        const unsigned char c = (unsigned char) s[at];
        if ((c & 0xC0) == 0x80) continue;              // pokračovací bajt
        size_t need = 1;
        if      ((c & 0xE0) == 0xC0) need = 2;
        else if ((c & 0xF0) == 0xE0) need = 3;
        else if ((c & 0xF8) == 0xF0) need = 4;
        // Celý znak se vešel? Pak je konec řetězce v pořádku.
        return (at + need <= s.size()) ? s.size() : at;
    }
    return i;
}

extern "C" {

JNIEXPORT void JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeBackendInit(JNIEnv *, jobject) {
    llama_backend_init();
    llama_log_set([](ggml_log_level lvl, const char *text, void *) {
        if (lvl >= GGML_LOG_LEVEL_WARN) LOGI("%s", text);
    }, nullptr);
}

JNIEXPORT jlong JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeLoad(
        JNIEnv *env, jobject, jstring jPath, jint nCtx, jint nThreads) {

    const char *path = env->GetStringUTFChars(jPath, nullptr);

    llama_model_params mp = llama_model_default_params();
    mp.n_gpu_layers = 0;        // telefony: CPU. Adreno/Mali přes Vulkan je zatím nestabilní.
    // Klíčové – model se mapuje z disku, nenačítá se celý do RAM.
    mp.load_mode    = LLAMA_LOAD_MODE_MMAP;

    llama_model *model = llama_model_load_from_file(path, mp);
    env->ReleaseStringUTFChars(jPath, path);

    if (!model) { LOGE("nepodarilo se nacist model"); return 0; }

    // Kontext je na telefonu to, co sežere nejvíc paměti po modelu samotném.
    // Když se nevejde, je lepší ubrat než spadnout.
    llama_context *ctx = nullptr;
    int used = nCtx;
    for (int tryCtx = nCtx; tryCtx >= 1024 && !ctx; tryCtx /= 2) {
        llama_context_params cp = llama_context_default_params();
        cp.n_ctx       = (uint32_t) tryCtx;
        cp.n_batch     = 512;
        cp.n_threads   = nThreads;
        cp.n_threads_batch = nThreads;
        cp.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_DISABLED;

        ctx = llama_init_from_model(model, cp);
        if (ctx) { used = tryCtx; break; }
        LOGE("kontext %d se nevesel, zkousim mensi", tryCtx);
    }
    if (!ctx) { llama_model_free(model); LOGE("nepodarilo se vytvorit kontext"); return 0; }
    nCtx = used;

    auto *z = new ZedCtx{model, ctx};
    LOGI("model nacten, n_ctx=%d, threads=%d", nCtx, nThreads);
    return reinterpret_cast<jlong>(z);
}

JNIEXPORT void JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeFree(JNIEnv *, jobject, jlong handle) {
    auto *z = reinterpret_cast<ZedCtx *>(handle);
    if (!z) return;
    if (z->ctx)   llama_free(z->ctx);
    if (z->model) llama_model_free(z->model);
    delete z;
}

JNIEXPORT void JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeResetContext(JNIEnv *, jobject, jlong handle) {
    auto *z = reinterpret_cast<ZedCtx *>(handle);
    if (z && z->ctx) {
        llama_memory_clear(llama_get_memory(z->ctx), true);
        z->cached.clear();
    }
}

// Generuje odpověď a každý token předá zpět do Kotlinu.
// Callback vrací false = uživatel generování zastavil.
JNIEXPORT void JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeGenerate(
        JNIEnv *env, jobject, jlong handle, jstring jPrompt,
        jint maxTokens, jfloat temp, jfloat topP, jint topK,
        jfloat repeatPenalty, jint seed, jobject callback) {

    auto *z = reinterpret_cast<ZedCtx *>(handle);
    if (!z) return;

    const llama_vocab *vocab = llama_model_get_vocab(z->model);

    // ── tokenizace promptu
    const char *prompt = env->GetStringUTFChars(jPrompt, nullptr);
    const int promptLen = (int) strlen(prompt);

    int nNeeded = -llama_tokenize(vocab, prompt, promptLen, nullptr, 0, true, true);
    std::vector<llama_token> tokens(nNeeded);
    llama_tokenize(vocab, prompt, promptLen, tokens.data(), nNeeded, true, true);
    env->ReleaseStringUTFChars(jPrompt, prompt);

    const int nCtx = (int) llama_n_ctx(z->ctx);
    if ((int) tokens.size() >= nCtx) {
        LOGE("prompt (%zu) nevejde do kontextu (%d)", tokens.size(), nCtx);
        return;
    }

    // Nová zpráva má s předchozí společný začátek (systémový prompt plus
    // historii). Co už v kontextu leží, se nepočítá znovu – jinak každá
    // další odpověď čeká o to déle, čím je rozhovor delší.
    size_t reuse = 0;
    while (reuse < z->cached.size() && reuse + 1 < tokens.size()
           && z->cached[reuse] == tokens[reuse]) {
        reuse++;
    }

    llama_memory_t mem = llama_get_memory(z->ctx);
    if (reuse == 0) llama_memory_clear(mem, true);
    else            llama_memory_seq_rm(mem, 0, (llama_pos) reuse, -1);

    LOGI("prompt %zu tokenu, z toho %zu uz spocitanych", tokens.size(), reuse);

    for (size_t i = reuse; i < tokens.size(); i += 512) {
        const int n = (int) std::min<size_t>(512, tokens.size() - i);
        llama_batch batch = llama_batch_get_one(tokens.data() + i, n);
        if (llama_decode(z->ctx, batch) != 0) {
            LOGE("decode promptu selhal");
            z->cached.clear();
            llama_memory_clear(mem, true);
            return;
        }
    }
    z->cached = tokens;

    // ── sampler
    auto sp = llama_sampler_chain_default_params();
    llama_sampler *smpl = llama_sampler_chain_init(sp);
    llama_sampler_chain_add(smpl, llama_sampler_init_penalties(
        llama_vocab_n_tokens(vocab), 64, repeatPenalty, 0.0f, 0.0f));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(topK));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(topP, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(temp));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist((uint32_t) seed));

    // ── callback
    jclass cbClass = env->GetObjectClass(callback);
    jmethodID onToken = env->GetMethodID(cbClass, "onToken", "(Ljava/lang/String;)Z");

    int nDecoded = (int) tokens.size();
    char piece[256];
    std::string pending;   // rozepsaný víceznakový znak

    for (int i = 0; i < maxTokens; i++) {
        llama_token tok = llama_sampler_sample(smpl, z->ctx, -1);

        if (llama_vocab_is_eog(vocab, tok)) break;

        const int n = llama_token_to_piece(vocab, tok, piece, sizeof(piece), 0, true);
        if (n > 0) {
            pending.append(piece, n);
            const size_t ready = utf8_complete_len(pending);
            if (ready > 0) {
                jstring js = env->NewStringUTF(pending.substr(0, ready).c_str());
                jboolean keepGoing = env->CallBooleanMethod(callback, onToken, js);
                env->DeleteLocalRef(js);
                pending.erase(0, ready);
                if (!keepGoing) break;
            }
        }

        llama_sampler_accept(smpl, tok);
        z->cached.push_back(tok);

        if (++nDecoded >= nCtx) { LOGI("kontext plny, konec generovani"); break; }

        llama_batch batch = llama_batch_get_one(&tok, 1);
        if (llama_decode(z->ctx, batch) != 0) { LOGE("decode selhal"); break; }
    }

    llama_sampler_free(smpl);
}

JNIEXPORT jint JNICALL
Java_world_zeds_ai_llm_LlamaBridge_nativeCountTokens(
        JNIEnv *env, jobject, jlong handle, jstring jText) {
    auto *z = reinterpret_cast<ZedCtx *>(handle);
    if (!z) return 0;
    const llama_vocab *vocab = llama_model_get_vocab(z->model);
    const char *text = env->GetStringUTFChars(jText, nullptr);
    const int n = -llama_tokenize(vocab, text, (int) strlen(text), nullptr, 0, true, true);
    env->ReleaseStringUTFChars(jText, text);
    return n;
}

} // extern "C"
