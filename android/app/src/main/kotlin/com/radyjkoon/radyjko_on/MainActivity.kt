package com.radyjkoon.radyjko_on

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterEngineProvider
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity(), FlutterEngineProvider {
    private val CHANNEL = "com.radyjkoon/tile"
    private var methodChannel: MethodChannel? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return com.ryanheise.audioservice.AudioServicePlugin.getFlutterEngine(context)
    }

    private val tileReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            methodChannel?.invokeMethod("togglePlayPause", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "updateTile") {
                val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                val stationName = call.argument<String>("stationName") ?: "RadyjkoON"
                
                val intent = Intent(this, RadioTileService::class.java).apply {
                    action = "UPDATE_TILE"
                    putExtra("isPlaying", isPlaying)
                    putExtra("stationName", stationName)
                }
                startService(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(tileReceiver, IntentFilter("com.radyjkoon.TILE_CLICKED"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(tileReceiver, IntentFilter("com.radyjkoon.TILE_CLICKED"))
        }
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(tileReceiver)
    }
}
