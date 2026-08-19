# iLikeIt — ProGuard / R8 Rules
# These rules prevent R8 from stripping classes that are accessed via reflection
# or are required by Flutter plugins at runtime.

# --- Flutter Engine ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# --- Kotlin ---
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# --- Flutter Secure Storage ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- sqflite (SQLite) ---
-keep class com.tekartik.sqflite.** { *; }

# --- url_launcher ---
-keep class io.flutter.plugins.urllauncher.** { *; }

# --- share_plus ---
-keep class dev.fluttercommunity.plus.share.** { *; }

# --- connectivity_plus ---
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# --- device_info_plus / package_info_plus ---
-keep class dev.fluttercommunity.plus.deviceinfo.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# --- app_links (deep linking) ---
-keep class com.llfbandit.app_links.** { *; }

# --- Suppress common warnings from transitive dependencies ---
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
