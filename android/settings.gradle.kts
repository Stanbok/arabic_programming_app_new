pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

plugins {
    // تحديث AGP وKotlin
    id("com.android.application") version "8.12.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.0" apply false

    // FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("com.google.firebase.firebase-perf") version "1.4.1" apply false
}

include(":app")
