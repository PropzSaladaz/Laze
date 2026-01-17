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

# Keep JSON serialization
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Dart Networking - Critical for UDP discovery and TCP connections
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all networking related classes
-keep class java.net.** { *; }
-dontwarn java.net.**

# Keep connectivity_plus plugin
-keep class io.flutter.plugins.connectivityplus.** { *; }
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Keep device_info_plus plugin
-keep class io.flutter.plugins.deviceinfo.** { *; }
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Keep logging framework
-keep class java.util.logging.** { *; }
-dontwarn java.util.logging.**

# Keep all model classes with json_serializable annotations
-keep @com.google.gson.annotations.SerializedName class * { *; }
-keep @retrofit2.http.* class * { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @retrofit2.http.* <methods>;
}

# Keep json_annotation classes
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# Keep all classes in data/dto package (JSON models)
-keep class com.propzsaladaz.laze.data.dto.** { *; }

# Keep all generated JSON adapters (*.g.dart files)
-keep class **$JsonSerializableGenerator { *; }
-keepclassmembers class * {
    *** fromJson(...);
    *** toJson(...);
}

# Don't warn about missing classes
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
