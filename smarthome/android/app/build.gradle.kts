plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Try to resolve an explicit ndk version in this order:
// 1) local.properties (keys: ndk.version or android.ndkVersion)
// 2) environment variable ANDROID_NDK_VERSION
// 3) project property "android.ndkVersion" (if passed via -P)
// 4) flutter.ndkVersion (the value provided by the Flutter plugin)
// 5) fallback default
val localProps = Properties().apply {
    val lp = rootProject.file("local.properties")
    if (lp.exists()) lp.inputStream().use { load(it) }
}
val ndkFromLocal = localProps.getProperty("ndk.version") ?: localProps.getProperty("android.ndkVersion")
val ndkFromEnv = System.getenv("ANDROID_NDK_VERSION")
val ndkFromProjectProp = if (project.hasProperty("android.ndkVersion")) project.property("android.ndkVersion") as? String else null
val defaultNdk = "21.4.7075529"
val resolvedNdk: String by lazy {
    ndkFromLocal ?: ndkFromEnv ?: ndkFromProjectProp ?: (try {
        // flutter may not be initialized at configuration time in some setups, so guard access
        val f = project.extensions.findByName("flutter")
        if (f != null) {
            val ndkProp = project.extra.properties["flutter.ndkVersion"] as? String
            ndkProp
        } else null
    } catch (_: Throwable) {
        null
    }) ?: defaultNdk
}

android {
    namespace = "com.example.smarthome"

    // Flutter plugin exposes compileSdkVersion/minSdkVersion/etc. Keep using those values.
    compileSdk = try {
        val v = project.extra.properties["flutter.compileSdkVersion"]
        (v as? Int) ?: 33
    } catch (_: Throwable) { 33 }

    // Use the resolved NDK version string (ensure that this version is installed in the Android SDK /ndk folder)
    ndkVersion = resolvedNdk

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID.
        applicationId = "com.example.smarthome"
        // Use values from the Flutter plugin if available, otherwise sensible defaults:
        minSdk = try {
            val v = project.extra.properties["flutter.minSdkVersion"]
            (v as? Int) ?: 21
        } catch (_: Throwable) { 21 }
        targetSdk = try {
            val v = project.extra.properties["flutter.targetSdkVersion"]
            (v as? Int) ?: 33
        } catch (_: Throwable) { 33 }
        versionCode = try {
            val v = project.extra.properties["flutter.versionCode"]
            (v as? Int) ?: 1
        } catch (_: Throwable) { 1 }
        versionName = try {
            val v = project.extra.properties["flutter.versionName"]
            (v as? String) ?: "1.0"
        } catch (_: Throwable) { "1.0" }
    }

    buildTypes {
        release {
            // Signing with the debug keys for now. Replace with your signing config for production.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}