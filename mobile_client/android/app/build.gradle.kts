import java.util.Properties
import java.io.FileInputStream
import java.security.KeyStore
import java.security.PrivateKey

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
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun releaseSigningValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)?.takeIf { it.isNotEmpty() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotEmpty() }

val releaseKeystorePath = releaseSigningValue("KEYSTORE_PATH", "storeFile")
val releaseKeystoreFile = releaseKeystorePath?.let { file(it) }
val releaseStorePassword = releaseSigningValue("KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseSigningValue("KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseSigningValue("KEY_PASSWORD", "keyPassword")

android {
    namespace = "com.propzsaladaz.laze"
    // Hardcoded rather than flutter.compileSdkVersion so target/compileSdk track
    // Google Play's API level mandate regardless of which Flutter version builds this.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    signingConfigs {
        create("release") {
            // Resolve each signing value from env vars first, then key.properties.
            storeFile = releaseKeystoreFile
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    defaultConfig {
        applicationId = "com.propzsaladaz.laze"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Always use the release signing config for the release build.
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

// Only release tasks require these credentials; debug builds remain usable without them.
val guardReleaseSigning by tasks.registering {
    group = "verification"
    description = "Ensure release signing credentials are present before building release"
    doLast {
        val missing = listOf(
            "KEYSTORE_PATH / storeFile" to releaseKeystorePath,
            "KEYSTORE_PASSWORD / storePassword" to releaseStorePassword,
            "KEY_ALIAS / keyAlias" to releaseKeyAlias,
            "KEY_PASSWORD / keyPassword" to releaseKeyPassword,
        ).filter { it.second.isNullOrEmpty() }.map { it.first }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "Missing Android release signing settings: ${missing.joinToString(", ")}. " +
                    "Set environment variables or android/key.properties. Release builds require a release keystore."
            )
        }
        if (releaseKeystoreFile?.isFile != true || !releaseKeystoreFile.canRead()) {
            throw GradleException("Android release keystore is missing or unreadable: $releaseKeystorePath")
        }
        try {
            val keystore = KeyStore.getInstance(releaseKeystoreFile, releaseStorePassword!!.toCharArray())
            val key = keystore.getKey(releaseKeyAlias!!, releaseKeyPassword!!.toCharArray())
            if (key !is PrivateKey || keystore.getCertificate(releaseKeyAlias) == null) {
                throw GradleException("The release key alias must identify a private key with a signing certificate")
            }
        } catch (error: Exception) {
            throw GradleException(
                "Unable to load the Android release signing key. Check the keystore, store password, key alias, and key password.",
                error,
            )
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild" || name == "validateSigningRelease") {
        dependsOn(guardReleaseSigning)
    }
}
