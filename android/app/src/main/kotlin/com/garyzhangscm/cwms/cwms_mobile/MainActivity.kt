package com.garyzhangscm.cwms.cwms_mobile

import android.net.Uri
import android.view.KeyEvent
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var rfid: RfidReader? = null
    private var scanFeedback: ScanFeedbackPlayer? = null
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        val triggerKeys = setOf(139, 280, 291, 293, 294, 311, 312, 313, 315, 591, 593, 594, 596)
        if (rfid?.active == true && rfid?.armed == true && keyCode in triggerKeys) {
            if (event.repeatCount == 0) rfid?.trigger()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
    override fun onPause() { rfid?.cancel(); super.onPause() }
    override fun onDestroy() { rfid?.close(); scanFeedback?.close(); super.onDestroy() }

    private val ocrChannelName = "cwms_mobile/vision_ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        rfid = RfidReader(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        scanFeedback = ScanFeedbackPlayer(flutterEngine.dartExecutor.binaryMessenger)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ocrChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("INVALID_PATH", "Image path is missing", null)
                    return@setMethodCallHandler
                }
                recognizeText(path, result)
            }
    }

    private fun recognizeText(path: String, result: MethodChannel.Result) {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    val recognized = text.textBlocks
                        .flatMap { block -> block.lines }
                        .map { line -> mapOf("text" to line.text) }
                    result.success(recognized)
                }
                .addOnFailureListener { error ->
                    result.error("OCR_FAILED", error.localizedMessage ?: "OCR failed", null)
                }
                .addOnCompleteListener {
                    recognizer.close()
                }
        } catch (error: Exception) {
            recognizer.close()
            result.error("OCR_FAILED", error.localizedMessage ?: "OCR failed", null)
        }
    }
}
