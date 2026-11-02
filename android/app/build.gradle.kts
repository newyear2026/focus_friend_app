import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter removes integration-test APKs on exit. The verification define keeps
// those APKs in a separate Android sandbox; see tool/verify_android.py.
val dartDefines = (project.findProperty("dart-defines") as? String).orEmpty()
    .split(',').mapNotNull { runCatching { String(Base64.getDecoder().decode(it)) }.getOrNull() }
val verificationApp = dartDefines.contains("FOCUS_FRIEND_VERIFICATION=true")
// Real AdMob app ID from admob.json (--dart-define-from-file); Google's sample
// app ID otherwise, which only serves test ads.
val admobAppId = dartDefines.firstOrNull { it.startsWith("ADMOB_APP_ID=") }
    ?.substringAfter('=')?.takeIf { it.isNotBlank() }
    ?: "ca-app-pub-3940256099942544~3347511713"

// Play upload key. android/key.properties is git-ignored; copy key.properties.example.
// Without it, release builds fall back to the debug key, which Play rejects.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) keystorePropertiesFile.inputStream().use { load(it) }
}
fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw GradleException("android/key.properties is missing '$name'.")

android {
    namespace = "dev.jaewook.prototype.focus_friend_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = if (verificationApp) "dev.jaewook.deskmate.verification"
            else "dev.jaewook.deskmate"
        manifestPlaceholders["appLabel"] = if (verificationApp) "Deskmate 검증" else "Deskmate"
        manifestPlaceholders["admobAppId"] = admobAppId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
                storePassword = keystoreProperty("storePassword")
                // Gradle does not expand "~", so resolve it against the home directory.
                storeFile = file(keystoreProperty("storeFile")
                    .replaceFirst(Regex("^~(?=/|$)"), System.getProperty("user.home")))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("android/key.properties not found: release build is signed with the debug key.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
