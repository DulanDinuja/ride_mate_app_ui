# ── Google Maps ──────────────────────────────────────────────────
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.dynamic.** { *; }
-keep class com.google.maps.** { *; }

# ── Keep Geolocator classes ─────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── Keep Flutter plugin registrants ─────────────────────────────
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ── Prevent stripping of annotations ────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# ── OkHttp / HTTP client ────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**

