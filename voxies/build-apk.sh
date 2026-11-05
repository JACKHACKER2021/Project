#!/usr/bin/env bash
# Sestaví debug APK (potřebuje Node, JDK 17+, Android SDK v ANDROID_HOME nebo android/local.properties, python3 + Pillow)
set -e
cd "$(dirname "$0")"
npm install
[ -d android ] || npx cap add android
python3 tools/android_setup.py
npx cap sync android
cd android && ./gradlew assembleDebug
echo "APK: $(pwd)/app/build/outputs/apk/debug/app-debug.apk"
