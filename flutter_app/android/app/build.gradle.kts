import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing. Secrets live in android/key.properties (gitignored — see
// android/key.properties.example). Debug/profile builds never need it; any
// *release* task fails fast when it is missing (see the check at the bottom)
// so a store build can never be silently signed with the debug keystore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.arzuman.livelyapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs the desugared java.time API on
        // older Android versions. Enabling core library desugaring lets it
        // build against a low minSdk without runtime crashes.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.arzuman.livelyapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Always the real release keystore. If key.properties is missing
            // the release tasks abort with a GradleException (see below).
            signingConfig = signingConfigs.getByName("release")
            // R8 code + resource shrinking. (The Flutter Gradle plugin also
            // turns these on by default; stated explicitly so it is visible.)
            // Plugin-specific keep rules live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// Fail any release build (assembleRelease, bundleRelease, …) when the release
// keystore config is missing. Evaluated once the task graph is known, so
// debug/profile builds and IDE sync keep working without key.properties.
gradle.taskGraph.whenReady {
    val releaseTask = allTasks.firstOrNull {
        it.project == project && it.name.contains("Release")
    }
    if (!hasReleaseSigning && releaseTask != null) {
        throw GradleException(
            "Release signing is not configured: android/key.properties was " +
                "not found (needed by task '${releaseTask.name}'). Copy " +
                "android/key.properties.example to android/key.properties and " +
                "point it at the upload keystore. Refusing to build a release " +
                "signed with debug keys."
        )
    }
}

dependencies {
    // Required by flutter_local_notifications (and any other plugin that
    // uses java.time / NIO APIs) when targeting older minSdk levels.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
