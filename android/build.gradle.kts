allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Provide a mock "flutter" extra-property map for plugin subprojects whose
// Groovy build.gradle references flutter.compileSdkVersion / flutter.minSdkVersion.
// The :app module already gets the real flutter extension from the Flutter Gradle Plugin.
subprojects {
    if (project.name != "app") {
        project.ext.set(
            "flutter",
            mapOf(
                "compileSdkVersion" to 35,
                "minSdkVersion"     to 21,
                "targetSdkVersion"  to 35,
                "ndkVersion"        to "27.0.12077973",
                "versionCode"       to 1,
                "versionName"       to "1.0.0"
            )
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
