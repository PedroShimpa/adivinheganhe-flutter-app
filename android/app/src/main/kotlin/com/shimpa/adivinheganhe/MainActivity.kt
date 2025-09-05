package com.shimpa.adivinheganhe

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "adivinheganhe/deeplink"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                // Retorna o link inicial (se existir)
                val initialLink: String? = intent?.data?.toString()
                result.success(initialLink)
            } else {
                result.notImplemented()
            }
        }
    }

    // Recebe novos intents quando o app já está aberto
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Envia o novo deep link para Flutter
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod("newIntent", intent.dataString)
    }
}
