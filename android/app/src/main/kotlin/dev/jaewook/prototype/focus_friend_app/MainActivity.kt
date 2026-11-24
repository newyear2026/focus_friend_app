package dev.jaewook.prototype.focus_friend_app

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.content.res.Resources
import android.database.sqlite.*
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import org.json.JSONObject
import java.util.Locale
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
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "focusFriendExit")
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "focusFriendExit", ExitNativeAdFactory(this))
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus_friend/store")
            .setMethodCallHandler { call, result ->
                if (call.method != "openListing") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // This channel runs on the main thread; opening another
                // activity must not use the local-storage worker below.
                try {
                    result.success(RecommendedPlayListings.open(this, call.argument<String>("packageName")))
                } catch (_: Exception) {
                    result.success(false)
                }
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
                if (call.method == "getLanguage") {
                    result.success(mapOf("app" to AppLanguage.get(this), "system" to AppLanguage.system()))
                    return@setMethodCallHandler
                }
                if (call.method == "setLanguage") {
                    AppLanguage.set(this, call.argument<String>("tag"))
                    result.success(null)
                    return@setMethodCallHandler
                }
                if (call.method == "keepScreenOn") {
                    // Window-scoped: Android drops it whenever this activity is not visible.
                    if (call.argument<Boolean>("on") == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
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
                            "getUpdateNews" -> AppUpdateNews.read(this)
                            "acknowledgeUpdateNews" -> {
                                AppUpdateNews.acknowledge(this, call.argument<Number>("build")!!.toLong())
                                null
                            }
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

/** Only the four curated app listings can be opened through this channel. */
object RecommendedPlayListings {
    private val PACKAGES = setOf(
        "com.dayround.app",
        "com.sobra.app.sobra_app",
        "com.randomfocus.app",
        "com.casewen.multi_calc"
    )

    fun open(activity: Activity, packageName: String?): Boolean {
        if (packageName !in PACKAGES) return false
        val marketUri = Uri.Builder().scheme("market").authority("details")
            .appendQueryParameter("id", packageName).build()
        val marketIntent = Intent(Intent.ACTION_VIEW, marketUri)
            .setPackage("com.android.vending")
        if (launch(activity, marketIntent)) return true

        val webUri = Uri.Builder().scheme("https").authority("play.google.com")
            .appendPath("store").appendPath("apps").appendPath("details")
            .appendQueryParameter("id", packageName).build()
        return launch(activity, Intent(Intent.ACTION_VIEW, webUri)
            .addCategory(Intent.CATEGORY_BROWSABLE))
    }

    private fun launch(activity: Activity, intent: Intent): Boolean = try {
        // Attempting directly works without package-visibility queries. This
        // also handles devices with no Play Store or no browser installed.
        activity.startActivity(intent)
        true
    } catch (_: Exception) {
        // Includes ActivityNotFoundException and SecurityException. If the
        // Play attempt fails, the caller tries the HTTPS listing next.
        false
    }
}

/** Announcement history follows installed builds, independently of focus data. */
object AppUpdateNews {
    private const val PREFS = "app_update_news"
    private const val LAST_BUILD = "last_acknowledged_build"

    @Suppress("DEPRECATION")
    private fun packageInfo(context: Context) =
        context.packageManager.getPackageInfo(context.packageName, 0)

    @Suppress("DEPRECATION")
    private fun buildCode(info: android.content.pm.PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    fun read(context: Context): Map<String, Any?> {
        val info = packageInfo(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return mapOf(
            "currentBuild" to buildCode(info),
            "lastAcknowledgedBuild" to if (prefs.contains(LAST_BUILD)) prefs.getLong(LAST_BUILD, 0) else null,
            "wasUpdated" to (info.lastUpdateTime > info.firstInstallTime)
        )
    }

    fun acknowledge(context: Context, build: Long) {
        require(build > 0 && build <= buildCode(packageInfo(context)))
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previous = prefs.getLong(LAST_BUILD, 0)
        // Never lower the watermark after a downgrade or a stale callback.
        if (build <= previous) return
        check(prefs.edit().putLong(LAST_BUILD, build).commit()) {
            "Could not save update-news acknowledgement"
        }
    }
}

/** The app language chosen in Settings; null follows the phone. */
object AppLanguage {
    private const val PREFS = "app_language"
    // Android 13+ keeps the choice itself and shares it with system Settings > Apps > Language.
    fun get(context: Context): String? =
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales.toLanguageTags().ifEmpty { null }
        } else context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("tag", null)
    fun set(context: Context, tag: String?) {
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales =
                if (tag == null) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(tag)
        } else {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("tag", tag).apply()
        }
    }
    fun system(): String = Resources.getSystem().configuration.locales[0].toLanguageTag()
    /** Notifications are built outside the activity; below 13 apply the choice by hand. */
    fun localized(context: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return context
        val tag = get(context) ?: return context
        val config = Configuration(context.resources.configuration)
        config.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(config)
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
        val text = AppLanguage.localized(context)
        notifications.createNotificationChannel(NotificationChannel(CHANNEL, text.getString(R.string.channel_complete), NotificationManager.IMPORTANCE_DEFAULT))
        val open = PendingIntent.getActivity(context, ID, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val mode = active.optString("mode")
        val title = text.getString(when(mode) { "demo" -> R.string.alert_demo_done; "rest" -> R.string.alert_rest_done; else -> R.string.alert_focus_done })
        notifications.notify(ID, Notification.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title).setContentText(text.getString(R.string.alert_body))
            .setContentIntent(open).setAutoCancel(true).build())
        // Notifications never mutate sessions, history, or rewards.
    }
}

class RoomAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try { RoomAlerts.deliver(context, intent) } catch (_: Exception) {}
    }
}
