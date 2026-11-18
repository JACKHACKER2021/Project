cmake_minimum_required(VERSION 3.22)
project(zedllm CXX)

set(CMAKE_CXX_STANDARD 17)

include(FetchContent)

# Pinnutá verze – llama.cpp mění API často, s jinou revizí se JNI vrstva
# nemusí přeložit. Při aktualizaci zkontroluj llama_sampler_* a llama_vocab_*.
FetchContent_Declare(
    llama_cpp
    GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
    GIT_TAG        b12504
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(llama_cpp)

add_library(zedllm SHARED llama_jni.cpp)

target_link_libraries(zedllm
    llama
    ggml
    android
    log
)
