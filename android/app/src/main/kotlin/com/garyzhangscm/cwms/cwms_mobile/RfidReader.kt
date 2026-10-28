package com.garyzhangscm.cwms.cwms_mobile

import android.os.Build
import com.rscja.deviceapi.exception.ConfigurationException
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.rscja.deviceapi.RFIDWithUHFUART
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import android.util.Log

/** Worker owns the SDK. Keep it initialized only while the RFID page is foreground. */
class RfidReader(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "cwms_mobile/rfid")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val epoch = AtomicInteger(0)
    // Accessed only on worker; there is never a second SDK owner.
    private var reader: RFIDWithUHFUART? = null
    private var originalPower: Int? = null
    private val powerPrefs = context.getSharedPreferences("rfid_pallet_settings", Context.MODE_PRIVATE)
    private fun savedPower() = powerPrefs.getInt("power_dbm", 10).coerceIn(5, 30)
    private fun preparePalletPower(reader: RFIDWithUHFUART, token: Int, target: Int = savedPower()) {
        val before = reader.getPower()
        check(before > 0) { "Unable to read RFID power" }
        require(target in 5..30) { "Invalid RFID power" }
        if (originalPower == null) originalPower = before
        Log.i("RfidPower", "mode=pallet beforeDbm=$before targetDbm=$target")
        if (before != target) check(reader.setPower(target)) { "Unable to set RFID power" }
        val actual = reader.getPower()
        check(actual == target) { "RFID power verification failed" }
        Log.i("RfidPower", "mode=pallet verifiedDbm=$actual")
        main.post {
            if (active && token == epoch.get()) {
                channel.invokeMethod("readerPower", mapOf("dbm" to actual))
            }
        }
    }
    private fun releaseReader() {
        try { reader?.stopInventory() } catch (_: Throwable) {}
        originalPower?.let { saved ->
            try {
                if (reader != null && reader!!.getPower() != saved) {
                    val restored = reader!!.setPower(saved) && reader!!.getPower() == saved
                    Log.i("RfidPower", "restoreDbm=$saved success=$restored")
                }
            } catch (_: Throwable) { Log.w("RfidPower", "Power restore failed") }
        }
        originalPower = null
        try { reader?.free() } catch (_: Throwable) {}
        reader = null
    }
    private fun ensureReader(): RFIDWithUHFUART {
        reader?.let { return it }
        val candidate = RFIDWithUHFUART.getInstance()
        try {
            check(candidate.init(context)) { "RFID initialization failed" }
            reader = candidate
            return candidate
        } catch (error: Throwable) {
            try { candidate.free() } catch (_: Throwable) {}
            throw error
        }
    }
    private val scanning = AtomicBoolean(false)
    private val palletStop = AtomicBoolean(false)
    private val palletRunning = AtomicBoolean(false)
    var armed = false
        private set
    @Volatile var active = false
        private set
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "capabilities" -> {
                    worker.execute {
                        var status = "unknown"
                        val verified = powerPrefs.getBoolean("hardware_verified", false)
                        val model = Build.MODEL.uppercase()
                        val vendor = (Build.MANUFACTURER + " " + Build.BRAND).lowercase()
                        val compatibleFamily = vendor.contains("chainway") || vendor.contains("rscja") ||
                            Regex("^(C5|C60|C61|C66|C70|C71|C72|C75|C76|C90|C6000|MC50|MC51|P80|H100|URA4|CW[0-9]+)([^0-9].*)?$").matches(model)
                        if (!compatibleFamily && !verified) {
                            status = "unsupported"
                        } else {
                            try {
                                check(ensureReader().getPower() > 0) { "No reader response" }
                                powerPrefs.edit().putBoolean("hardware_verified", true).apply()
                                status = "available"
                            } catch (_: ConfigurationException) {
                                status = if (verified) "unavailable" else "unsupported"
                            } catch (_: Throwable) {
                                // No response cannot prove absence: retain previously verified hardware.
                                status = if (verified) "unavailable" else "unknown"
                            } finally {
                                if (!active) releaseReader()
                            }
                        }
                        Log.i("RfidCapability", "status=$status")
                        main.post { result.success(status) }
                    }
                }
                "arm" -> { armed = call.arguments == true; result.success(null) }
                "activate" -> {
                    active = true
                    val token = epoch.get()
                    val palletMode = call.argument<Boolean>("palletMode") == true
                    worker.execute {
                        if (active && token == epoch.get()) {
                            try {
                                val ready = ensureReader()
                                if (palletMode && active && token == epoch.get()) preparePalletPower(ready, token)
                            } catch (_: Throwable) {
                                Log.w("RfidPower", "Reader preparation failed")
                                releaseReader()
                            }
                            if (!active || token != epoch.get()) releaseReader()
                        }
                    }
                    result.success(null)
                }
                "deactivate" -> { active = false; armed = false; cancel(); result.success(null) }
                "cancel" -> { cancel(); result.success(null) }
                "setPalletPower" -> {
                    val power = call.argument<Int>("dbm")
                    if (power == null || power !in 5..30) {
                        result.error("INVALID_POWER", "Choose 5 to 30 dBm", null)
                    } else if (!active || !scanning.compareAndSet(false, true)) {
                        result.error("BUSY", "Stop scanning before changing power", null)
                    } else {
                        val token = epoch.get()
                        worker.execute {
                            var success = false
                            try {
                                check(active && token == epoch.get()) { "Cancelled" }
                                preparePalletPower(ensureReader(), token, power)
                                check(active && token == epoch.get()) { "Cancelled" }
                                powerPrefs.edit().putInt("power_dbm", power).apply()
                                success = true
                            } catch (_: Throwable) { releaseReader() }
                            main.post {
                                scanning.set(false)
                                if (success && active && token == epoch.get()) result.success(power)
                                else result.error("POWER_FAILED", "Power change not verified", null)
                            }
                        }
                    }
                }
                "stopPallet" -> { palletStop.set(true); result.success(null) }
                "scanPallet" -> {
                    val session = call.argument<Int>("session")
                    if (session == null) result.error("INVALID_SESSION", "Missing scan session", null)
                    else startPallet(session, result)
                }
                "scan" -> {
                    if (!active || !scanning.compareAndSet(false, true)) {
                        result.error("BUSY", "Reader not active or busy", null)
                    } else {
                        val token = epoch.get()
                        worker.execute {
                            var failure: String? = null
                            val tags = linkedSetOf<String>()
                            val started = SystemClock.elapsedRealtime()
                            var ready = started
                            var stopped = started
                            try {
                                check(token == epoch.get() && active) { "Cancelled" }
                                val reader = ensureReader()
                                ready = SystemClock.elapsedRealtime()
                                check(token == epoch.get() && active) { "Cancelled" }
                                reader.setInventoryCallback(null)
                                // Discard any buffered reads from a previous reader session.
                                var drained = 0
                                while (reader.readTagFromBuffer() != null && drained++ < 10000) {}
                                check(drained < 10000) { "Reader buffer did not clear" }
                                check(reader.startInventoryTag()) { "RFID scan failed" }
                                val end = SystemClock.elapsedRealtime() + 1800
                                while (token == epoch.get() && active && SystemClock.elapsedRealtime() < end) {
                                    val epc = reader.readTagFromBuffer()?.epc
                                    if (!epc.isNullOrBlank()) tags.add(epc.trim().uppercase())
                                    if (tags.size > 1) break
                                    if (epc == null) Thread.sleep(10)
                                }
                                check(reader.stopInventory()) { "RFID stop failed" }
                                stopped = SystemClock.elapsedRealtime()
                                // Include reads queued before stop so a second tag is not missed.
                                var remaining = 0
                                while (token == epoch.get() && active && tags.size < 2) {
                                    val tag = reader.readTagFromBuffer() ?: break
                                    if (!tag.epc.isNullOrBlank()) tags.add(tag.epc.trim().uppercase())
                                    check(++remaining < 10000) { "Too many buffered reads" }
                                }
                            } catch (e: Throwable) {
                                failure = e.javaClass.simpleName
                            } finally {
                                if (failure != null || token != epoch.get() || !active) releaseReader()
                                Log.d("RfidTiming", "initMs=${ready - started} inventoryMs=${stopped - ready} totalMs=${SystemClock.elapsedRealtime() - started}")
                            }
                            val wasCancelled = token != epoch.get() || !active
                            main.post {
                                scanning.set(false)
                                if (failure != null || wasCancelled || token != epoch.get() || !active) result.error("RFID_UNAVAILABLE", failure ?: "Cancelled", null)
                                else result.success(tags.toList())
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    fun trigger() {
        if (active && (!scanning.get() || palletRunning.get())) channel.invokeMethod("trigger", null)
    }
    private fun startPallet(session: Int, result: MethodChannel.Result) {
        if (!active || !scanning.compareAndSet(false, true)) {
            result.error("BUSY", "Reader not active or busy", null)
            return
        }
        palletStop.set(false)
        palletRunning.set(true)
        val token = epoch.get()
        worker.execute {
            val seen = linkedSetOf<String>()
            val batch = arrayListOf<String>()
            var failure: String? = null
            var reason = "stopped"
            fun emit() {
                if (batch.isEmpty()) return
                val snapshot = batch.toList()
                batch.clear()
                main.post {
                    if (active && token == epoch.get()) {
                        channel.invokeMethod("palletTags", mapOf("session" to session, "epcs" to snapshot))
                    }
                }
            }
            fun add(epc: String?) {
                if (epc.isNullOrBlank()) return
                val normalized = epc.trim().uppercase()
                if (seen.add(normalized)) batch.add(normalized)
            }
            try {
                check(active && token == epoch.get()) { "Cancelled" }
                val reader = ensureReader()
                check(active && token == epoch.get()) { "Cancelled" }
                preparePalletPower(reader, token)
                reader.setInventoryCallback(null)
                var drained = 0
                while (reader.readTagFromBuffer() != null && drained++ < 10000) {}
                check(drained < 10000) { "Reader buffer did not clear" }
                check(reader.startInventoryTag()) { "RFID scan failed" }
                val deadline = SystemClock.elapsedRealtime() + 300000
                var nextUpdate = SystemClock.elapsedRealtime() + 150
                while (active && token == epoch.get() && !palletStop.get()) {
                    val epc = reader.readTagFromBuffer()?.epc
                    add(epc)
                    val now = SystemClock.elapsedRealtime()
                    if (now >= nextUpdate) { emit(); nextUpdate = now + 150 }
                    if (seen.size >= 50000 || now >= deadline) { reason = "limit"; break }
                    if (epc == null) Thread.sleep(10)
                }
                check(reader.stopInventory()) { "RFID stop failed" }
                var remaining = 0
                while (active && token == epoch.get() && seen.size < 50000) {
                    val tag = reader.readTagFromBuffer() ?: break
                    add(tag.epc)
                    check(++remaining < 100000) { "Too many buffered reads" }
                }
                emit()
            } catch (error: Throwable) {
                failure = error.javaClass.simpleName
            } finally {
                if (failure != null || !active || token != epoch.get()) releaseReader()
            }
            main.post {
                palletRunning.set(false)
                scanning.set(false)
                if (failure != null || !active || token != epoch.get()) {
                    result.error("RFID_UNAVAILABLE", failure ?: "Cancelled", null)
                } else {
                    // Final complete batch protects against a delayed UI callback.
                    result.success(mapOf("reason" to reason, "epcs" to seen.toList()))
                }
            }
        }
    }
    fun cancel() {
        epoch.incrementAndGet()
        if (!worker.isShutdown) worker.execute { releaseReader() }
    }
    fun close() { active = false; cancel(); channel.setMethodCallHandler(null); worker.shutdown() }
}
