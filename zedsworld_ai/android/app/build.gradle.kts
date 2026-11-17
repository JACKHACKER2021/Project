plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace  = "world.zeds.ai"
    compileSdk = 35

    defaultConfig {
        applicationId = "world.zeds.ai"
        minSdk        = 28          // Android 9; starší telefony model neunesou
        targetSdk     = 35
        versionCode   = 1
        versionName   = "0.1"

        // Model se do APK nevejde (2,5 GB, Play limit 150 MB) – stahuje se při
        // prvním spuštění. arm64 je jediná relevantní architektura pro 4B model.
        ndk { abiFilters += listOf("arm64-v8a") }

        externalNativeBuild {
            cmake {
                // Q4_K_M + ARM dotprod/i8mm = výrazně rychlejší prompt processing
                arguments += listOf(
                    "-DGGML_OPENMP=OFF",
                    "-DGGML_LLAMAFILE=OFF",
                    "-DLLAMA_CURL=OFF",
                    "-DLLAMA_BUILD_COMMON=ON",
                    "-DCMAKE_BUILD_TYPE=Release"
                )
                cppFlags += listOf("-O3", "-fexceptions", "-frtti")
            }
        }

        // Python (Chaquopy) se přidá ve fázi 5 – viz README
    }

    signingConfigs {
        create("zed") {
            storeFile = file("zed-release.jks")
            storePassword = System.getenv("ZED_KS_PASS") ?: "zedsworld"
            keyAlias = "zed"
            keyPassword = System.getenv("ZED_KEY_PASS") ?: "zedsworld"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("zed")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"),
                          "proguard-rules.pro")
        }
    }

    externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt") } }

    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    packaging { jniLibs { useLegacyPackaging = false } }
}

dependencies {
    val compose = "1.7.5"
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation(platform("androidx.compose:compose-bom:2024.11.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.documentfile:documentfile:1.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // PDF: extrakce textu z nahraných souborů
    // BouncyCastle (60 MB dexu) je v PdfBoxu jen pro šifrovaná PDF – nepotřebujeme
    implementation("com.tom-roush:pdfbox-android:2.0.27.0") {
        exclude(group = "org.bouncycastle")
    }
    // OCR pro skenované PDF se doplní ve fázi 5 (ML Kit přidá ~60 MB do APK)
}
