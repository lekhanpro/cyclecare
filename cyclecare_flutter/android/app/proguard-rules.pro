# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.android.gms.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Crypto
-keep class javax.crypto.** { *; }

# Google Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
