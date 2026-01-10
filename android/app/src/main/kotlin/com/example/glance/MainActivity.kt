package com.example.glance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var weatherAiChannel: WeatherAiChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        weatherAiChannel = WeatherAiChannel(
            this,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    override fun onDestroy() {
        weatherAiChannel?.dispose()
        super.onDestroy()
    }
}
