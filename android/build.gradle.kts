// android/build.gradle.kts

plugins {
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

// توحيد مجلدات build
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.value(newSubprojectBuildDir)
}

// التأكد أن app يُقيَّم أولًا
subprojects {
    evaluationDependsOn(":app")
}

// الحل الصحيح لتوحيد compileSdk
subprojects {

    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
        }
    }

    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
        }
    }
}

// clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
