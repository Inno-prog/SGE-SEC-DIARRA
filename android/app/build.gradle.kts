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

    signingConfigs {
        create("upload") {
            storeFile = rootProject.file(project.findProperty("MYAPP_UPLOAD_STORE_FILE") as String? ?: "../upload-keystore.jks")
            storePassword = project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as String? ?: "sge_secdiarra"
            keyAlias = project.findProperty("MYAPP_UPLOAD_KEY_ALIAS") as String? ?: "upload"
            keyPassword = project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as String? ?: "sge_secdiarra"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("upload")
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
