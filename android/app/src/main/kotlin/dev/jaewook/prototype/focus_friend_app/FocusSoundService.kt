package dev.jaewook.prototype.focus_friend_app

import android.app.*
import android.content.*
import android.media.*
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.*

/** Offline ambience. This service never writes focus records or rewards. */
class FocusSoundService : Service() {
    companion object {
        private const val CHANNEL = "focus_ambience"
        private const val ID = 41018
        var current: FocusSoundService? = null
        var lastError: String? = null
        private var interruptedSession: String? = null

        fun configure(context: Context, args: Map<*, *>) {
            val command = args["command"] as? String ?: "stop"
            if (command == "stop") {
                current?.stopSelf()
                return
            }
            if (command == "update" && current == null) return
            val session = args["session"] as? String
            val activate = args["activate"] == true
            if (!activate && session != null && interruptedSession == session) return
            if (activate) interruptedSession = null
            val sound = args["sound"] as? String ?: "rain"
            require(sound in listOf("rain", "forest", "fire"))
            val intent = Intent(context, FocusSoundService::class.java)
                .putExtra("sound", sound)
                .putExtra("volume", (args["volume"] as? Number)?.toFloat() ?: .4f)
                .putExtra("endAt", (args["endAt"] as? Number)?.toLong() ?: 0L)
                .putExtra("session", session)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent)
            else context.startService(intent)
        }

        fun status(): Map<String, Any?> = mapOf(
            "playing" to (current?.playing == true),
            "sound" to current?.sound,
            "error" to lastError,
            "endAt" to current?.endAt,
        )
    }

    private var player: MediaPlayer? = null
    private var mediaSession: MediaSession? = null
    private lateinit var audioManager: AudioManager
    private var focusRequest: AudioFocusRequest? = null
    private var focusGranted = false
    private var volume = .4f
    private var duck = 1f
    private var sound: String? = null
    private var session: String? = null
    private var endAt = 0L
    private var playing = false
    private var generation = 0
    private val handler = Handler(Looper.getMainLooper())
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build()
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_GAIN -> { duck = 1f; applyVolume() }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> { duck = .2f; applyVolume() }
            else -> { interruptedSession = session; stopSelf() }
        }
    }
    private val noisy = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            interruptedSession = session
            stopSelf()
        }
    }
    private val deadline = object : Runnable {
        override fun run() {
            if (endAt > 0 && System.currentTimeMillis() >= endAt) {
                stopSelf()
                return
            }
            applyVolume()
            handler.postDelayed(this, 200)
        }
    }

    override fun onCreate() {
        super.onCreate()
        current = this
        lastError = null
        audioManager = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, "집중 사운드", NotificationManager.IMPORTANCE_LOW))
        }
        mediaSession = MediaSession(this, "FocusAmbience").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onStop() { interruptedSession = session; stopSelf() }
            })
            isActive = true
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(noisy, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY), RECEIVER_NOT_EXPORTED)
        else registerReceiver(noisy, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            interruptedSession = session
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent == null) { stopSelf(); return START_NOT_STICKY }
        session = intent.getStringExtra("session")
        endAt = intent.getLongExtra("endAt", 0)
        volume = intent.getFloatExtra("volume", .4f).coerceIn(0f, 1f)
        val next = intent.getStringExtra("sound") ?: "rain"
        startForeground(ID, notification(next))
        if (endAt > 0 && System.currentTimeMillis() >= endAt) { stopSelf(); return START_NOT_STICKY }
        if (!focusGranted) {
            val result = if (Build.VERSION.SDK_INT >= 26) {
                focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener).build()
                audioManager.requestAudioFocus(focusRequest!!)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
            }
            focusGranted = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            if (!focusGranted) { lastError = "Audio focus unavailable"; stopSelf(); return START_NOT_STICKY }
        }
        if (next != sound || player == null) load(next) else applyVolume()
        handler.removeCallbacks(deadline)
        handler.post(deadline)
        return START_NOT_STICKY
    }

    private fun load(next: String) {
        val request = ++generation
        playing = false
        player?.release()
        sound = next
        val newPlayer = MediaPlayer()
        player = newPlayer
        try {
            newPlayer.setAudioAttributes(attributes)
            newPlayer.setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
            assets.openFd("flutter_assets/assets/audio/$next.mp3").use { asset ->
                newPlayer.setDataSource(asset.fileDescriptor, asset.startOffset, asset.length)
            }
            newPlayer.isLooping = true
            newPlayer.setOnErrorListener { _, what, extra ->
                lastError = "Playback error $what/$extra"; stopSelf(); true
            }
            newPlayer.setOnPreparedListener { prepared ->
                if (request != generation) return@setOnPreparedListener
                if (endAt > 0 && System.currentTimeMillis() >= endAt) { stopSelf(); return@setOnPreparedListener }
                lastError = null
                applyVolume()
                prepared.start()
                playing = true
                mediaSession?.setPlaybackState(PlaybackState.Builder().setActions(PlaybackState.ACTION_STOP)
                    .setState(PlaybackState.STATE_PLAYING, 0, 1f).build())
            }
            newPlayer.prepareAsync()
        } catch (e: Exception) { lastError = e.message; stopSelf() }
    }

    private fun applyVolume() {
        val fade = if (endAt > 0) ((endAt - System.currentTimeMillis()) / 800f).coerceIn(0f, 1f) else 1f
        val level = volume * duck * fade
        player?.setVolume(level, level)
    }

    private fun notification(id: String): Notification {
        val title = when (id) { "forest" -> "숲의 바람"; "fire" -> "따뜻한 장작"; else -> "창밖의 비" }
        val open = PendingIntent.getActivity(this, ID, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, ID, Intent(this, FocusSoundService::class.java).setAction("STOP"), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder.setSmallIcon(android.R.drawable.ic_media_play).setContentTitle(title)
            .setContentText("집중 사운드 재생 중").setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(android.R.drawable.ic_media_pause, "소리 끄기", stop).build())
            .setStyle(Notification.MediaStyle().setMediaSession(mediaSession!!.sessionToken).setShowActionsInCompactView(0)).build()
    }

    override fun onTaskRemoved(rootIntent: Intent?) { stopSelf() }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onDestroy() {
        ++generation
        handler.removeCallbacksAndMessages(null)
        playing = false
        player?.release(); player = null
        mediaSession?.release()
        if (focusGranted) {
            if (Build.VERSION.SDK_INT >= 26) focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            else { @Suppress("DEPRECATION") audioManager.abandonAudioFocus(focusListener) }
        }
        unregisterReceiver(noisy)
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (current === this) current = null
        super.onDestroy()
    }
}
