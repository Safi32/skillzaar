import java.util.Properties


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.skillzaar.worker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.skillzaar.worker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // reCAPTCHA Enterprise configuration
        // Get your site key from Firebase Console > Authentication > Sign-in method > Phone
        resValue("string", "recaptcha_site_key", "6Lf...") // Replace with your actual site key
    }
    // Load key.properties
    val keystoreProperties = Properties()
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        keystoreProperties.load(keystoreFile.inputStream())
    }

    fun signingValue(propertyName: String, envName: String): String? {
        return keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }
            ?: System.getenv(envName)?.takeIf { it.isNotBlank() }
    }

    val storeFilePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
    val storePasswordValue = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
    val keyAliasValue = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
    val keyPasswordValue = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")

    val allowDebugSigningForRelease =
        (signingValue("allowDebugSigningForRelease", "ALLOW_DEBUG_SIGNING_FOR_RELEASE") == "true")

    val useReleaseSigning = !storeFilePath.isNullOrBlank()

    signingConfigs {
        if (useReleaseSigning) {
            create("release") {
                storeFile = file(storeFilePath!!)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = when {
                useReleaseSigning -> signingConfigs.getByName("release")
                allowDebugSigningForRelease -> signingConfigs.getByName("debug")
                else -> throw GradleException(
                    "Release signing is not configured. Provide android/key.properties with 'storeFile', " +
                        "or set env ANDROID_KEYSTORE_PATH/ANDROID_KEYSTORE_PASSWORD/ANDROID_KEY_ALIAS/ANDROID_KEY_PASSWORD."
                )
            }
            
        }
    }

    bundle {
        storeArchive {
            enable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

apply(plugin = "com.google.gms.google-services")
