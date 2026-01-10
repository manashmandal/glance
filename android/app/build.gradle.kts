plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.glance"
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
        applicationId = "com.example.glance"
        minSdk = 26  // Required for ML Kit GenAI
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ML Kit GenAI Summarization (includes Gemini Nano)
    implementation("com.google.mlkit:genai-summarization:1.0.0-beta1")
    // Coroutines support for ListenableFuture (required for ML Kit await())
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.7.3")
}

flutter {
    source = "../.."
}
