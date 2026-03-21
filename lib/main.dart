import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialise the Google Maps Android renderer ──────────────────
  // Forces the latest (or legacy) renderer so the map actually renders
  // in release / profile builds on physical devices.
  _initGoogleMapsRenderer();

  if (kDebugMode) {
    debugPrint('┌─────────────────────────────────────');
    debugPrint('│ ENV      : ${AppConfig.environment}');
    debugPrint('│ BASE_URL : ${AppConfig.baseUrl}');
    debugPrint('└─────────────────────────────────────');
  }

  runApp(const RideMateApp());
}

/// Explicitly request the **latest** Cloud-based Maps renderer on Android.
/// This avoids the blank-map issue that occurs in release builds when the
/// renderer is not initialised before the first GoogleMap widget is created.
void _initGoogleMapsRenderer() {
  final GoogleMapsFlutterPlatform platform = GoogleMapsFlutterPlatform.instance;
  if (platform is GoogleMapsFlutterAndroid) {
    // Use AndroidMapRenderer.latest for the newest renderer.
    // If the map is still blank on your device, try AndroidMapRenderer.legacy instead.
    platform.useAndroidViewSurface = true;
    platform.initializeWithRenderer(AndroidMapRenderer.latest);
  }
}

class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Mate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.getStarted,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

