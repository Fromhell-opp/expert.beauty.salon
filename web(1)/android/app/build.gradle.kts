plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "kg.expert.beauty.salon"
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
        // ✅ Финальный Android package name
        applicationId = "kg.expert.beauty.salon"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // временно debug ключ (для flutter run)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // 🔥 Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // 🔥 Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
