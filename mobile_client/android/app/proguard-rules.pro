# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive
-keep class hive.** { *; }
-keep class com.hive.** { *; }

# Keep JSON serialization attributes
-keepattributes *Annotation*

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Dart Networking - Critical for UDP discovery and TCP connections
-keep class io.flutter.embedding.** { *; }

# Keep all networking related classes - essential for RawDatagramSocket and Socket
-keep class java.net.** { *; }
-dontwarn java.net.**
-keep class java.nio.** { *; }
-dontwarn java.nio.**

# Keep connectivity_plus plugin - used for WiFi checks
-keep class io.flutter.plugins.connectivityplus.** { *; }
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep device_info_plus plugin - used for device identification
-keep class io.flutter.plugins.deviceinfo.** { *; }
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Keep logging framework - used throughout the app
-keep class java.util.logging.** { *; }
-dontwarn java.util.logging.**

# Don't warn about missing optional dependencies
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
