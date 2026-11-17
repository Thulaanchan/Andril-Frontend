plugins {
    id("com.android.application")
    // Apply the Flutter Gradle plugin after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.andril.mobile"
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.andril.mobile"
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Flutter's generated snapshot paths can use extended UNC syntax on Windows.
// Normalize the depfile targets so Gradle tracks the individual output files.
fun normalizeFlutterDepfile(depfile: File) {
    if (!depfile.isFile) return

    val contents = depfile.readText()
    val separator = contents.indexOf(": ")
    if (separator < 0) return

    val targets = contents.substring(0, separator)
    val normalizedTargets = targets.replace("""\\\\?\\UNC\\""", """\\\\""")
    if (targets != normalizedTargets) {
        depfile.writeText(normalizedTargets + contents.substring(separator))
    }
}

if (System.getProperty("os.name").startsWith("Windows", ignoreCase = true)) {
    val flutterBuildTasks = tasks.withType<com.flutter.gradle.tasks.FlutterTask>()
    gradle.projectsEvaluated {
        flutterBuildTasks.forEach { task ->
            task.outputDirectory?.resolve("flutter_build.d")?.let(::normalizeFlutterDepfile)
        }
    }
    flutterBuildTasks.configureEach {
        val flutterTask = this
        doLast {
            flutterTask.outputDirectory?.resolve("flutter_build.d")?.let(::normalizeFlutterDepfile)
        }
    }
}
