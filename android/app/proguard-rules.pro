# Keep audio_service classes for foreground notification
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media3.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter plugin registrants
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.** { *; }

# Keep permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Fix R8 Play Core missing classes
-dontwarn com.google.android.play.core.**
