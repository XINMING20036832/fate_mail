pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        require(localPropertiesFile.exists()) {
            "local.properties not found. flutter.sdk must be set for Gradle includeBuild."
        }
        localPropertiesFile.inputStream().use { properties.load(it) }
        val path = properties.getProperty("flutter.sdk")
        require(!path.isNullOrBlank()) { "flutter.sdk not set in local.properties" }
        path
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

include(":app")
