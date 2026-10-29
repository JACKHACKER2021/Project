"""Úpravy Android projektu po `npx cap add android`: na šířku, celá obrazovka, ikona s Voxiem."""
import os, re, shutil, sys
from PIL import Image

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
app = os.path.join(root, 'android', 'app', 'src', 'main')

man = os.path.join(app, 'AndroidManifest.xml')
s = open(man).read()
if 'screenOrientation' not in s:
    s = s.replace('<activity', '<activity android:screenOrientation="sensorLandscape"', 1)
open(man, 'w').write(s)

# celá obrazovka (skryté lišty, výřez displeje)
styles = os.path.join(app, 'res', 'values', 'styles.xml')
s = open(styles).read()
if 'windowFullscreen' not in s:
    s = re.sub(r'(<style name="AppTheme.NoActionBar"[^>]*>)', r'\1\n        <item name="android:windowFullscreen">true</item>\n        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>', s)
open(styles, 'w').write(s)

java = None
for d, _, fs in os.walk(os.path.join(app, 'java')):
    for f in fs:
        if f == 'MainActivity.java':
            java = os.path.join(d, f)
pkg = open(java).read().split(';')[0]
open(java, 'w').write(pkg + """;

import android.os.Bundle;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // hudba v menu bez nutnosti dotyku
        getBridge().getWebView().getSettings().setMediaPlaybackRequiresUserGesture(false);
        hideBars();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideBars();
    }

    private void hideBars() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat c = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        c.hide(WindowInsetsCompat.Type.systemBars());
        c.setSystemBarsBehavior(WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }
}
""")

# verze aplikace
gradle = os.path.join(root, 'android', 'app', 'build.gradle')
g = open(gradle).read()
g = re.sub(r'versionCode \d+', 'versionCode 10', g); g = re.sub(r'versionName "[^"]*"', 'versionName "1.0.0"', g)
open(gradle, 'w').write(g)

# stejný podpisový klíč pro všechny verze (aby šla aktualizace bez odinstalace a postup zůstal)
ks = os.path.join(root, 'keystore', 'voxies.keystore')
if os.path.exists(ks):
    home_ks = os.path.expanduser('~/.android/debug.keystore')
    os.makedirs(os.path.dirname(home_ks), exist_ok=True)
    shutil.copyfile(ks, home_ks)

# ikona
icon = Image.open(os.path.join(root, 'icon.png')).convert('RGBA')
res = os.path.join(app, 'res')
shutil.rmtree(os.path.join(res, 'mipmap-anydpi-v26'), ignore_errors=True)
for name, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    d = os.path.join(res, 'mipmap-' + name)
    os.makedirs(d, exist_ok=True)
    for f in ('ic_launcher.png', 'ic_launcher_round.png', 'ic_launcher_foreground.png'):
        icon.resize((size, size), Image.LANCZOS).save(os.path.join(d, f))
print('android setup ok')
