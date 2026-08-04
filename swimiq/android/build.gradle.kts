allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Some Flutter plugins pin an older compileSdk than the app. When the app
    // and its transitive AndroidX dependencies require a newer API level, that
    // skew fails `checkReleaseAarMetadata`. Align every Android subproject's
    // compileSdk with the app's (36) without touching plugin sources. Uses
    // reflection so it works with AGP 9's new DSL extension types. Registered
    // before `evaluationDependsOn` below so subprojects aren't already
    // evaluated when the callback is added.
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        runCatching {
            val getCompileSdk = androidExtension.javaClass.methods
                .firstOrNull { it.name == "getCompileSdk" && it.parameterCount == 0 }
            val setCompileSdk = androidExtension.javaClass.methods
                .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
            val current = getCompileSdk?.invoke(androidExtension) as? Int
            if (setCompileSdk != null && (current == null || current < 36)) {
                setCompileSdk.invoke(androidExtension, 36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
