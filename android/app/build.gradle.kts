import java.util.Base64

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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (verificationApp) "dev.jaewook.prototype.focus_friend_app.verification"
            else "dev.jaewook.prototype.focus_friend_app"
        manifestPlaceholders["appLabel"] = if (verificationApp) "집중방 화면 검증" else "작은 집중방 Dev"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
