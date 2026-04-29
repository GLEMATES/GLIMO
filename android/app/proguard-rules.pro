# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Geolocator - Fix background service crash
-keep class com.baseflow.geolocator.** { *; }
-keep interface com.baseflow.geolocator.** { *; }
-keepclassmembers class com.baseflow.geolocator.** { *; }

# Background services - CRITICAL untuk prevent crash
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.common.wrappers.** { *; }

# In-app purchase
-keep class com.android.billingclient.api.** { *; }

# Activity Recognition
-keep class com.google.android.gms.location.** { *; }

# Prevent obfuscation of background service names
-keepnames class * extends android.app.Service
-keepnames class * extends android.content.BroadcastReceiver

# Keep all native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core - Don't warn about missing classes (not using dynamic delivery)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Flutter Play Store split - keep but ignore if missing
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
