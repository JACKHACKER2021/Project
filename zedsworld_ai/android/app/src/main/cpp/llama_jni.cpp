// JNI most mezi Kotlinem a llama.cpp.
//
// Pozor: llama.cpp mění API často. Tento soubor je psaný proti tagu b4585
// (viz CMakeLists.txt). Při aktualizaci zkontroluj hlavně llama_sampler_*,
// llama_vocab_* a llama_kv_cache_clear.

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
};

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
    mp.use_mmap     = true;     // klíčové – model se nenačítá celý do RAM
    mp.use_mlock    = false;

    llama_model *model = llama_model_load_from_file(path, mp);
    env->ReleaseStringUTFChars(jPath, path);

    if (!model) { LOGE("nepodarilo se nacist model"); return 0; }

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx       = (uint32_t) nCtx;
    cp.n_batch     = 512;
    cp.n_threads   = nThreads;
    cp.n_threads_batch = nThreads;
    cp.flash_attn  = false;

    llama_context *ctx = llama_init_from_model(model, cp);
    if (!ctx) { llama_model_free(model); LOGE("nepodarilo se vytvorit kontext"); return 0; }

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
    if (z && z->ctx) llama_kv_cache_clear(z->ctx);
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

    llama_kv_cache_clear(z->ctx);

    // ── zpracování promptu po dávkách
    for (size_t i = 0; i < tokens.size(); i += 512) {
        const int n = (int) std::min<size_t>(512, tokens.size() - i);
        llama_batch batch = llama_batch_get_one(tokens.data() + i, n);
        if (llama_decode(z->ctx, batch) != 0) { LOGE("decode promptu selhal"); return; }
    }

    // ── sampler
    auto sp = llama_sampler_chain_default_params();
    llama_sampler *smpl = llama_sampler_chain_init(sp);
    llama_sampler_chain_add(smpl, llama_sampler_init_penalties(64, repeatPenalty, 0.0f, 0.0f));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(topK));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(topP, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(temp));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist((uint32_t) seed));

    // ── callback
    jclass cbClass = env->GetObjectClass(callback);
    jmethodID onToken = env->GetMethodID(cbClass, "onToken", "(Ljava/lang/String;)Z");

    int nDecoded = (int) tokens.size();
    char piece[256];

    for (int i = 0; i < maxTokens; i++) {
        llama_token tok = llama_sampler_sample(smpl, z->ctx, -1);

        if (llama_vocab_is_eog(vocab, tok)) break;

        const int n = llama_token_to_piece(vocab, tok, piece, sizeof(piece), 0, true);
        if (n > 0) {
            jstring js = env->NewStringUTF(std::string(piece, n).c_str());
            jboolean keepGoing = env->CallBooleanMethod(callback, onToken, js);
            env->DeleteLocalRef(js);
            if (!keepGoing) break;
        }

        llama_sampler_accept(smpl, tok);

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
