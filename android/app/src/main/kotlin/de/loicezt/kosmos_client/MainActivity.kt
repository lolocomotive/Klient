package de.loicezt.kosmos_client

import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat 

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.navigationBarColor = 0x30000000
        window.statusBarColor = 0
    }
}
