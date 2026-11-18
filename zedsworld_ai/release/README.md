# Zeds World AI — APK

`ZedsWorld-AI-v0.1.apk` — podepsaná release verze, 8,4 MB, arm64-v8a, Android 9+.

Podpis: `CN=Zeds World, O=Jackhack, C=CZ`, SHA-256
`9b07c5c43a6c6b1ccbec3ea50fbd0b3a30fc26472231ababd9f1ca7c0e4255a5`.

## Instalace

Přenes APK do telefonu a otevři ho. Android se zeptá na povolení
instalace z neznámého zdroje. Aplikace si při prvním spuštění stáhne
model (cca 2,5 GB), takže potřebuje Wi-Fi a místo na disku.

Model **není** v APK — GitHub nepustí soubor nad 100 MB. Model se bere
z adresy v `ModelRepository.DEFAULT_URL`, nebo ho lze zabalit do APK
podle `app/src/main/assets/README.txt` a přeložit vlastní build.

## Co v této verzi je

Chat s modelem offline, roleplay režim, workshop (HTML / three.js /
GDScript / SVG do souborů), náhled v WebView, export Godot projektu
jako ZIP, čtení textu z PDF, tisk HTML do PDF.

## Co v ní není

Vlastní dotrénovaný model Zeda — natrénovaná 0.6B verze zní špatně
česky a plete si fakta, takže se do APK nedává. Dál OCR skenovaných
PDF a Python; obojí je naplánované.
