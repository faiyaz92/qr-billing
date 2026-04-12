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

// Workaround for older plugins that don't declare `namespace` (required by AGP 8+).
subprojects {
    afterEvaluate {
        if (name == "bluetooth_print") {
            extensions.findByName("android")?.let { androidExt ->
                val setNamespaceMethod = androidExt.javaClass.methods.firstOrNull {
                    it.name == "setNamespace" && it.parameterTypes.size == 1
                }
                setNamespaceMethod?.invoke(androidExt, "com.example.bluetooth_print")
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
