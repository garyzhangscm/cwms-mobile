package com.garyzhangscm.cwms.cwms_mobile

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** App rejection tone, independent of the scanner hardware's decode beep. */
class ScanFeedbackPlayer(messenger: BinaryMessenger) {
    private val handler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "cwms_mobile/scan_feedback")
    private var tone: ToneGenerator? = null
    private var closed = false
    private val pending = java.util.ArrayDeque<MethodChannel.Result>()
    private var playing = false

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "failure") result.notImplemented()
            else if (closed) result.success(null)
            else { pending.add(result); playNext() }
        }
    }

    private fun playNext() {
        if (playing || closed || pending.isEmpty()) return
        playing = true
        val result = pending.removeFirst()
        try {
            // Negative-acknowledgement warble; never the scanner's decode tone.
            val player = tone ?: ToneGenerator(AudioManager.STREAM_MUSIC, 85).also { tone = it }
            player.startTone(ToneGenerator.TONE_PROP_NACK, 350)
        } catch (_: Exception) { /* Visual failure remains authoritative. */ }
        handler.postDelayed({
            result.success(null)
            playing = false
            playNext()
        }, 500)
    }

    fun close() {
        closed = true
        channel.setMethodCallHandler(null)
        // Let the currently scheduled completion resolve its Flutter future.
        while (!pending.isEmpty()) pending.removeFirst().success(null)
        tone?.release()
        tone = null
    }
}
