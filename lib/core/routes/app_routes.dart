import 'package:flutter/material.dart';
import '../../screens/get_started_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/email_verification_screen.dart';
import '../../screens/login_success_screen.dart';
import '../../screens/home_map_screen.dart';

class AppRoutes {
  // Route names
  static const String getStarted = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String loginSuccess = '/login-success';
  static const String homeMap = '/home-map';

  // Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case getStarted:
        return MaterialPageRoute(builder: (_) => const GetStartedScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      
      case emailVerification:
        final email = settings.arguments as String?;
        if (email == null) {
          return _errorRoute('Email is required');
        }
        return MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: email),
        );
      
      case loginSuccess:
        return MaterialPageRoute(builder: (_) => const LoginSuccessScreen());
      
      case homeMap:
        return MaterialPageRoute(builder: (_) => const HomeMapScreen());
      
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  // Error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
