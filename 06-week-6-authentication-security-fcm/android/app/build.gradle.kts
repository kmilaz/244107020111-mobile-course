plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// FCM: membaca android/app/google-services.json. Kalau file itu tidak ada,
// Firebase.initializeApp() gagal dan aplikasi menonaktifkan fitur FCM sendiri.
apply(plugin = "com.google.gms.google-services")

android {
    namespace = "com.example.mobile_week_6"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // WAJIB untuk flutter_local_notifications: plugin itu memakai API Java 8+
        // yang perlu di-desugar agar jalan di perangkat Android lama.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mobile_week_6"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Library pendukung desugaring di atas. Naikkan versinya bila diminta
    // flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// FCM / Firebase.
//
// Konfigurasi diambil dari android/app/google-services.json oleh plugin
// google-services di atas. Kalau file itu tidak ada, build tetap berhasil tetapi
// Firebase.initializeApp() gagal dan aplikasi menonaktifkan fitur FCM sendiri
// (lihat `firebaseReady` di lib/messaging/push_service.dart).
//
// Langkah pemasangan lengkapnya ada di README.md bagian "Mengaktifkan FCM".
// ---------------------------------------------------------------------------
