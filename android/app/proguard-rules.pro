# CycleCare ProGuard Rules

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# Riverpod / Dart
-keep class com.google.** { *; }
-dontwarn com.google.**

# Local notifications
-keep class com.dexterous.** { *; }

# Supabase / Realtime
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# OkHttp (used by Dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Gson (JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# Biometric
-keep class androidx.biometric.** { *; }

# Secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep all model classes
-keep class com.lekhanpro.cyclecare.** { *; }

# General Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
