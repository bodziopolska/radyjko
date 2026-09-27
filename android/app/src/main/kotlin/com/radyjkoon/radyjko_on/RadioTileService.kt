package com.radyjkoon.radyjko_on

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class RadioTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onClick() {
        super.onClick()
        // Broadcast the click to MainActivity if it's running
        val intent = Intent("com.radyjkoon.TILE_CLICKED")
        sendBroadcast(intent)
        
        // Also try to launch the app if it's not in the foreground
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivityAndCollapse(launchIntent)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "UPDATE_TILE") {
            val isPlaying = intent.getBooleanExtra("isPlaying", false)
            val stationName = intent.getStringExtra("stationName") ?: "RadyjkoON"
            
            val tile = qsTile
            if (tile != null) {
                tile.state = if (isPlaying) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
                tile.label = stationName
                tile.updateTile()
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    private fun updateTileState() {
        val tile = qsTile
        if (tile != null) {
            // Default state until Flutter updates it
            if (tile.state == Tile.STATE_UNAVAILABLE) {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "RadyjkoON"
                tile.updateTile()
            }
        }
    }
}
