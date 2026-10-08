package dev.jaewook.prototype.focus_friend_app

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.database.sqlite.*
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.Executors

class SnapshotDb(context: Context, scope: String = "focus") :
    SQLiteOpenHelper(context, "$scope.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE snapshot (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL, body TEXT NOT NULL)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        throw IllegalStateException("Unsupported database version")
    }
    fun read(): String? = readableDatabase.rawQuery("SELECT body FROM snapshot WHERE id=1", null).use {
        if (it.moveToFirst()) it.getString(0) else null
    }
    fun commit(body: String, expected: Int, revision: Int, fail: Boolean = false) {
        val json = JSONObject(body)
        require(json.getInt("schema") == 1 && json.getInt("revision") == revision)
        require(revision == expected + 1)
        val db = writableDatabase
        db.beginTransaction()
        try {
            val current = db.rawQuery("SELECT revision FROM snapshot WHERE id=1", null).use {
                if (it.moveToFirst()) it.getInt(0) else 0
            }
            check(current == expected) { "Revision conflict: reload required" }
            db.execSQL("INSERT OR REPLACE INTO snapshot(id,revision,body) VALUES(1,?,?)", arrayOf(revision, body))
            if (fail) throw IllegalStateException("Injected failure before COMMIT")
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
    }
}

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus_friend/sound")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "configure" -> { FocusSoundService.configure(this, call.arguments as Map<*, *>); result.success(null) }
                        "status" -> result.success(FocusSoundService.status())
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) { result.error("AUDIO", e.message, null) }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus_friend/local")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestAlerts") {
                    if (Build.VERSION.SDK_INT >= 33 && !RoomAlerts.enabled(this)) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 501)
                    }
                    result.success(null)
                    return@setMethodCallHandler
                }
                worker.execute {
                    try {
                        val scope = call.argument<String>("scope") ?: "focus"
                        val debug = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
                        require(scope == "focus" || (debug && scope == "verification"))
                        val value: Any? = when (call.method) {
                            "load" -> SnapshotDb(this, scope).use { it.read() }
                            "commit" -> {
                                SnapshotDb(this, scope).use { it.commit(
                                    call.argument<String>("json")!!,
                                    call.argument<Int>("expected")!!,
                                    call.argument<Int>("revision")!!,
                                    debug && scope == "verification" && call.argument<Boolean>("fail") == true) }
                                if (scope == "focus") {
                                    // Scheduling is a best-effort side effect; never undo a durable save.
                                    try { RoomAlerts.sync(this) } catch (_: Exception) {}
                                }
                                null
                            }
                            "alertsEnabled" -> RoomAlerts.enabled(this)
                            "syncAlerts" -> { RoomAlerts.sync(this); null }
                            else -> throw IllegalArgumentException("Unknown operation")
                        }
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("LOCAL_STORAGE", e.message, null) }
                    }
                }
            }
    }
}

object RoomAlerts {
    private const val CHANNEL = "room_completion"
    private const val ID = 41017
    fun enabled(context: Context): Boolean =
        context.getSystemService(NotificationManager::class.java).areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    private fun pending(context: Context, session: JSONObject? = null): PendingIntent {
        val intent = Intent(context, RoomAlarmReceiver::class.java)
            .putExtra("session", session?.optString("id"))
            .putExtra("endAt", session?.optLong("endAt") ?: 0L)
        return PendingIntent.getBroadcast(context, ID, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun sync(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java)
        manager.cancel(pending(context))
        context.getSystemService(NotificationManager::class.java).cancel(ID)
        val raw = SnapshotDb(context).use { it.read() } ?: return
        val active = JSONObject(raw).optJSONObject("active") ?: return
        if (!enabled(context) || active.optString("status") != "running") return
        val end = active.getLong("endAt")
        if (end <= System.currentTimeMillis()) return
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, end, pending(context, active))
    }
    fun deliver(context: Context, intent: Intent) {
        if (!enabled(context)) return
        val raw = SnapshotDb(context).use { it.read() } ?: return
        val active = JSONObject(raw).optJSONObject("active") ?: return
        if (active.optString("id") != intent.getStringExtra("session") ||
            active.optString("status") != "running" ||
            active.optLong("endAt") != intent.getLongExtra("endAt", 0) ||
            System.currentTimeMillis() < active.optLong("endAt")) return
        val notifications = context.getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel(CHANNEL, "집중과 휴식 완료", NotificationManager.IMPORTANCE_DEFAULT))
        val open = PendingIntent.getActivity(context, ID, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val mode = active.optString("mode")
        val title = when(mode) { "demo" -> "1분 체험이 끝났어요"; "rest" -> "휴식이 끝났어요"; else -> "집중 시간이 끝났어요" }
        notifications.notify(ID, Notification.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title).setContentText("작은 방으로 돌아와 고양이를 만나세요.")
            .setContentIntent(open).setAutoCancel(true).build())
        // Notifications never mutate sessions, history, or rewards.
    }
}

class RoomAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try { RoomAlerts.deliver(context, intent) } catch (_: Exception) {}
    }
}
