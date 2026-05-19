import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Signing config (Bug 4 fix) ────────────────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// ─────────────────────────────────────────────────────────────────────────────

android {
    namespace = "com.anonymous.nove_mobile_flutter"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // Bug 3 fix: migrate off deprecated jvmTarget String DSL
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // Bug 4 fix: release signing config block
    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias     = keystoreProperties["keyAlias"]      as String
                keyPassword  = keystoreProperties["keyPassword"]   as String
                storeFile    = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.anonymous.nove_mobile_flutter"
        // Bug 1 fix: flutter_overlay_window requires SYSTEM_ALERT_WINDOW (API 23+)
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // bumped to match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Bug 4 fix: use release keystore when key.properties exists,
            // fall back to debug only for CI environments without the keystore.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            isMinifyEnabled    = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
