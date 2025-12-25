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

// التأكد أن app يُقيَّم أولًا (مسموح وآمن)
subprojects {
    evaluationDependsOn(":app")
}

// clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
