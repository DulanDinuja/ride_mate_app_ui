import 'package:flutter/material.dart';
import '../../screens/get_started_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/email_verification_screen.dart';
import '../../screens/login_success_screen.dart';
import '../../screens/home_map_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/profile_completion_screen.dart';
import '../../screens/user_verification_screen.dart';
import '../../screens/identification_document_screen.dart';
import '../../screens/identification_success_screen.dart';
import '../../screens/vehicle_registration_screen.dart';
import '../../screens/vehicle_photos_upload_screen.dart';
import '../../screens/driving_license_upload_screen.dart';
import '../../screens/vehicle_insurance_upload_screen.dart';
import '../../screens/revenue_license_upload_screen.dart';
import '../../models/user_verification_args.dart';

class AppRoutes {
  // Route names
  static const String getStarted = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String loginSuccess = '/login-success';
  static const String homeMap = '/home-map';
  static const String forgotPassword = '/forgot-password';
  static const String profileCompletion = '/profile-completion';
  static const String userVerification = '/user-verification';
  static const String identificationDocument = '/identification-document';
  static const String identificationSuccess = '/identification-success';
  static const String vehicleRegistration = '/vehicle-registration';
  static const String vehiclePhotosUpload = '/vehicle-photos-upload';
  static const String drivingLicenseUpload = '/driving-license-upload';
  static const String vehicleInsuranceUpload = '/vehicle-insurance-upload';
  static const String revenueLicenseUpload = '/revenue-license-upload';

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

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case profileCompletion:
        return MaterialPageRoute(builder: (_) => const ProfileCompletionScreen());

      case userVerification:
        final args = settings.arguments;
        if (args is! UserVerificationArgs) {
          return _errorRoute('User verification details are missing');
        }
        return MaterialPageRoute(
          builder: (_) => UserVerificationScreen(args: args),
        );

      case identificationDocument:
        final args = settings.arguments;
        if (args is! UserVerificationArgs) {
          return _errorRoute('Identification document details are missing');
        }
        return MaterialPageRoute(
          builder: (_) => IdentificationDocumentScreen(args: args),
        );

      case identificationSuccess:
        return MaterialPageRoute(builder: (_) => const IdentificationSuccessScreen());

      case vehicleRegistration:
        return MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen());

      case vehiclePhotosUpload:
        return MaterialPageRoute(builder: (_) => const VehiclePhotosUploadScreen());

      case drivingLicenseUpload:
        return MaterialPageRoute(builder: (_) => const DrivingLicenseUploadScreen());

      case vehicleInsuranceUpload:
        return MaterialPageRoute(builder: (_) => const VehicleInsuranceUploadScreen());

      case revenueLicenseUpload:
        return MaterialPageRoute(builder: (_) => const RevenueLicenseUploadScreen());

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
