import com.android.build.gradle.AppExtension
import com.android.build.gradle.LibraryExtension

plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            if (namespace == null) {
                namespace = "com.plugin.fixed.${project.name.replace("-", ".").replace("_", ".")}"
            }
            compileSdkVersion(36)
        }

        // Fix for "Setting the namespace via the package attribute... is no longer supported"
        val fixManifestTask = tasks.register("fixManifestForNamespace") {
            doLast {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        println("Fixing manifest for ${project.name}: removing legacy package attribute")
                        manifestFile.writeText(content.replace(Regex("""package="[^"]*""""), ""))
                    }
                }
            }
        }
        tasks.named("preBuild") {
            dependsOn(fixManifestTask)
        }
    }
    plugins.withId("com.android.application") {
        extensions.configure<AppExtension> {
            compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
