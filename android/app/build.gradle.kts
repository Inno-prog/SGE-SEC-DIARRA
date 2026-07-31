plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sge.secdiarra"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.sge.secdiarra"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.create("release")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file(project.findProperty("MYAPP_UPLOAD_STORE_FILE") ?: "upload-keystore.jks")
            storePassword = project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD") ?: "sge_secdiarra"
            keyAlias = project.findProperty("MYAPP_UPLOAD_KEY_ALIAS") ?: "upload"
            keyPassword = project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") ?: "sge_secdiarra"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
