plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_new_chat_app_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_new_chat_app_test"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        
        pickFirst("**/libaosl.so")
        doNotStrip("**/*.so")

        exclude("lib/arm64-v8a/libaosl.so")
        exclude("lib/armeabi-v7a/libaosl.so")
        exclude("lib/x86/libaosl.so")
        exclude("lib/x86_64/libaosl.so")
        
        excludes.add("META-INF/LICENSE.md")
        excludes.add("META-INF/LICENSE-notice.md")
        excludes.add("META-INF/NOTICE.md")
        excludes.add("META-INF/NOTICE")
        excludes.add("META-INF/LICENSE")
        excludes.add("META-INF/*.txt")
        excludes.add("META-INF/*.kotlin_module")
    }
}

flutter {
    source = "../.."
}