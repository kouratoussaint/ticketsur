plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ticketsur.fasosoft"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identifiant définitif dès la première publication Google Play (décision du 2026-11-18).
        applicationId = "com.ticketsur.fasosoft"
        // Android 7.0 minimum (cahier §14.4) ; API 36 exigée par Google Play depuis le 31/08/2026.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signature de publication : fournie UNIQUEMENT par l'environnement (secrets
    // GitHub), jamais par un fichier du dépôt. Sans elle, l'APK de pilote est
    // signée avec la clé de débogage : installable, mais refusée par Google Play.
    val releaseKeystore = System.getenv("TICKETSUR_KEYSTORE_PATH")
    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("TICKETSUR_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("TICKETSUR_KEY_ALIAS")
                keyPassword = System.getenv("TICKETSUR_KEY_PASSWORD")
            }
        }
    }

    // L'analyse lint de publication plante sur le code Java d'image_picker
    // (bogue de lint : NoSuchMethodError dans JavaDocParser). Elle n'apporte
    // rien au build de pilote ; l'analyse Dart (`flutter analyze`) reste
    // bloquante dans la CI.
    lint {
        checkReleaseBuilds = false
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystore != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
