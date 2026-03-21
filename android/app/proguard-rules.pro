# ── Google Maps ──────────────────────────────────────────────────
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.dynamic.** { *; }
-keep class com.google.maps.** { *; }
# Required for google_maps_flutter Android renderer
-keep class io.flutter.plugins.googlemaps.** { *; }
-keep class com.google.android.gms.internal.maps.** { *; }

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

# ── Play Core (referenced by Flutter deferred components) ────────
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

