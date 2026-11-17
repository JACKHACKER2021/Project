# JNI vstupní body nesmí být přejmenovány
-keep class world.zeds.ai.llm.LlamaBridge { *; }

# PdfBox bez BouncyCastle – nechat chybět třídy pro šifrovaná PDF
-dontwarn org.bouncycastle.**
-dontwarn com.tom_roush.pdfbox.pdmodel.encryption.**
-keep class com.tom_roush.pdfbox.** { *; }

# Compose / Kotlin coroutines
-dontwarn kotlinx.coroutines.**

# JPEG2000 dekodér v PdfBoxu je volitelný – obrázky v PDF nepotřebujeme
-dontwarn com.gemalto.jp2.**
