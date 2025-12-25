// android/build.gradle.kts

plugins {
    // Firebase Google Services (يُطبّق فقط على app)
    id("com.google.gms.google-services") version "4.4.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

// توحيد مجلدات build لكل المشروع
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// التأكد أن app يُقيَّم قبل باقي الموديولات
subprojects {
    project.evaluationDependsOn(":app")
}

// حل مشكلة compileSdk لجميع الموديولات (app + plugins مثل app_links)
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")) {

            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(34)
            }
        }
    }
}

// مهمة التنظيف
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
