import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Safely Load Keystore Properties (used by GitHub Actions)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()

if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val dartDefines = project.findProperty("dart-defines") as String?
val decodedDefines = mutableMapOf<String, String>()

dartDefines?.split(",")?.forEach {
    val decoded = String(Base64.getDecoder().decode(it))
    val parts = decoded.split("=")
    if (parts.size == 2) {
        decodedDefines[parts[0]] = parts[1]
    }
}

android {
    namespace = "app.workfloow"
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
        applicationId = "app.workfloow"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = decodedDefines["GOOGLE_MAPS_API_KEY"] ?: ""
    }

    // Create the Release Signing Config (Only if properties exist)
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Conditionally apply the signing config
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release") // Used by GitHub for Play Store
            } else {
                signingConfigs.getByName("debug") // Safe fallback for local testing
            }
        }
    }
}

flutter {
    source = "../.."
}
