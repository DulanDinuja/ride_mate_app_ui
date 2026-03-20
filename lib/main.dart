import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('┌─────────────────────────────────────');
    debugPrint('│ ENV      : ${AppConfig.environment}');
    debugPrint('│ BASE_URL : ${AppConfig.baseUrl}');
    debugPrint('└─────────────────────────────────────');
  }

  runApp(const RideMateApp());
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

