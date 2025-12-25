plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin (لازم ييجي بعد Android و Kotlin)
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Services (Auth / Firestore / Analytics …)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.python_in_arabic"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.python_in_arabic"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // تعطيل Firebase Performance نهائيًا (أمان إضافي)
        resValue("bool", "firebase_performance_collection_enabled", "false")

        // دعم arm64 فقط (زي OPPO A7)
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    buildTypes {
        release {
            // مؤقتًا Debug signing
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM – إدارة النسخ تلقائيًا
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Firebase Services المستخدمة فعليًا
    implementation("com.google.firebase:firebase-auth")
}
