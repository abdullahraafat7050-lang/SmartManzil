import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Put top-level build outputs outside the repository, e.g. ../../build
val newBuildDir: File = rootProject.file("../../build")
rootProject.buildDir = newBuildDir

subprojects {
    // each subproject gets its own directory inside the new root build dir, e.g. ../../build/<projectName>
    project.buildDir = File(rootProject.buildDir, project.name)

    // if you really need subprojects to evaluate after :app, keep this (use with care)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}