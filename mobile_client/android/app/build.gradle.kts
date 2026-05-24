import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties is a plain key=value file that lives at android/key.properties.
// It is the local-developer alternative to environment variables — you fill it in
// once on your machine so you don't have to export env vars before every build.
// It is intentionally excluded from git (.gitignore) so credentials are never committed.
// In CI the file does not exist; signing credentials are passed via env vars instead.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.propzsaladaz.laze"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            // Android release builds must be signed with a keystore (.jks file).
            // A keystore holds 4 pieces of info: the file path, the password to open
            // the keystore, the alias of the specific key inside it, and that key's password.
            //
            // Resolution order for each value (first non-empty wins):
            //   1. Environment variable  — used in CI (GitHub Actions injects these as secrets)
            //   2. key.properties entry  — used locally (file on the developer's machine)
            //   3. Hardcoded fallback     — last resort so Gradle never receives a null/empty path
            //
            // takeIf { it.isNotEmpty() } is required because Kotlin's ?: operator only
            // skips null, not "". Without it, an env var explicitly set to "" would be
            // passed straight to file(), which throws: "path may not be null or empty string".

            // storeFile — path to the .jks keystore file on disk
            storeFile = file(
                System.getenv("KEYSTORE_PATH")?.takeIf { it.isNotEmpty() }
                    ?: keystoreProperties.getProperty("storeFile")?.takeIf { it.isNotEmpty() }
                    ?: "upload-keystore.jks"
            )
            // storePassword — password to unlock/open the keystore file itself
            storePassword = System.getenv("KEYSTORE_PASSWORD")?.takeIf { it.isNotEmpty() }
                ?: keystoreProperties.getProperty("storePassword") ?: ""
            // keyAlias — name of the specific signing key inside the keystore
            keyAlias = System.getenv("KEY_ALIAS")?.takeIf { it.isNotEmpty() }
                ?: keystoreProperties.getProperty("keyAlias") ?: "upload"
            // keyPassword — password for the individual key (can differ from storePassword)
            keyPassword = System.getenv("KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
                ?: keystoreProperties.getProperty("keyPassword") ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.propzsaladaz.laze"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release signing config only when a real keystore is available:
            //   - in CI:    KEYSTORE_PATH env var is set (non-null) by the decode-keystore step
            //   - locally:  key.properties file exists on the developer's machine
            // Otherwise fall back to the debug signing config so unsigned local builds still work.
            signingConfig = if (keystorePropertiesFile.exists() || System.getenv("KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
