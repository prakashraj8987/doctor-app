plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    // Flutter Gradle Plugin must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.factodoctor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // Explicit NDK version to avoid mismatch issues

    defaultConfig {
        applicationId = "com.example.factodoctor"
        minSdk = 23  // ← CHANGED: Updated from flutter.minSdkVersion to 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // Add this for Firebase
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Required for flutter_local_notifications
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // Use debug signing config for now (replace with your release config later)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for java.time and other desugared APIs used by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")  // Uncommented for your telemedicine app
    implementation("com.google.firebase:firebase-firestore")  // Uncommented for your telemedicine app
    implementation("com.google.firebase:firebase-storage")  // Uncommented for your telemedicine app
    implementation("com.google.firebase:firebase-messaging")  // Uncommented for your telemedicine app
    
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}