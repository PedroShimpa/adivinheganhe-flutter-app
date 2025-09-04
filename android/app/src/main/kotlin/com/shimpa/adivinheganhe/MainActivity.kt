package com.shimpa.adivinheganhe

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "adivinheganhe/deeplink"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Escuta novos intents vindos do Android
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { _, _ -> }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Envia para Flutter
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod("newIntent", intent.dataString)
    }
}
