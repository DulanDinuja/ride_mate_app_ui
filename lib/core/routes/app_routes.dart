import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import '../../screens/get_started_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/email_verification_screen.dart';
import '../../screens/login_success_screen.dart';
import '../../screens/home_map_screen.dart';
import '../../screens/user_home_map_screen.dart';
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
import '../../screens/ride_start_screen.dart';
import '../../screens/ride_requests_screen.dart';
import '../../screens/navigation_screen.dart';
import '../../screens/passenger_tracking_screen.dart';
import '../../screens/cost_split_screen.dart';
import '../../screens/active_ride_screen.dart';
import '../../screens/manage_vehicle_profiles_screen.dart';
import '../../screens/payment_methods_screen.dart';
import '../../screens/payment_history_screen.dart';
import '../../screens/driver_wallet_screen.dart';
import '../../screens/withdrawal_request_screen.dart';
import '../../screens/withdrawal_history_screen.dart';
import '../../models/user_verification_args.dart';
import '../../models/driver_registration_data.dart';
import '../../models/user_profile.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String getStarted = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String loginSuccess = '/login-success';
  static const String homeMap = '/home-map';
  static const String userHomeMap = '/user-home-map';
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
  static const String rideStart = '/ride-start';
  static const String driverHomeMap = '/driver-home-map';
  static const String driverNavigation = '/driver-navigation';
  static const String navigation = '/navigation';
  static const String costSplit = '/cost-split';
  static const String activeRide = '/active-ride';
  static const String rideRequests = '/ride-requests';
  static const String manageVehicleProfiles = '/manage-vehicle-profiles';
  static const String passengerTracking = '/passenger-tracking';

  // ─── Payment routes ──────────────────────────────────────────────
  static const String paymentMethods = '/payment-methods';
  static const String paymentHistory = '/payment-history';
  static const String driverWallet = '/driver-wallet';
  static const String withdrawalRequest = '/withdrawal-request';
  static const String withdrawalHistory = '/withdrawal-history';

  // Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
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

      case userHomeMap:
        return MaterialPageRoute(builder: (_) => const UserHomeMapScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case profileCompletion:
        return MaterialPageRoute(
          builder: (_) => ProfileCompletionScreen(existingProfile: settings.arguments as UserProfile?),
          settings: settings,
        );

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
        final data = settings.arguments;
        if (data is! DriverRegistrationData) {
          return _errorRoute('Vehicle registration data is missing');
        }
        return MaterialPageRoute(
          builder: (_) => const VehiclePhotosUploadScreen(),
          settings: settings,
        );

      case drivingLicenseUpload:
        final data = settings.arguments;
        if (data is! DriverRegistrationData) {
          return _errorRoute('Vehicle registration data is missing');
        }
        return MaterialPageRoute(
          builder: (_) => const DrivingLicenseUploadScreen(),
          settings: settings,
        );

      case vehicleInsuranceUpload:
        final data = settings.arguments;
        if (data is! DriverRegistrationData) {
          return _errorRoute('Vehicle registration data is missing');
        }
        return MaterialPageRoute(
          builder: (_) => const VehicleInsuranceUploadScreen(),
          settings: settings,
        );

      case revenueLicenseUpload:
        final data = settings.arguments;
        if (data is! DriverRegistrationData) {
          return _errorRoute('Vehicle registration data is missing');
        }
        return MaterialPageRoute(
          builder: (_) => const RevenueLicenseUploadScreen(),
          settings: settings,
        );

      case rideStart:
        return MaterialPageRoute(
          builder: (_) => const RideStartScreen(),
          settings: settings,
        );

      case driverHomeMap:
        return MaterialPageRoute(builder: (_) => const UserHomeMapScreen());

      case driverNavigation:
      case navigation:
        final args = settings.arguments;
        if (args is! NavigationArgs) {
          return _errorRoute('Navigation args are missing');
        }
        return MaterialPageRoute(
          builder: (_) => NavigationScreen(args: args),
        );

      case costSplit:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CostSplitScreen(
              rideDetailId: args['rideDetailId'] as int?,
              isDriver: args['isDriver'] as bool? ?? false,
            ),
          );
        }
        return _errorRoute('Cost split data is missing');

      case activeRide:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ActiveRideScreen(
              rideDetailId: args['rideDetailId'] as int,
              driverProfileId: args['driverProfileId'] as int?,
              pickupAddress: args['pickupAddress'] as String? ?? '',
              dropAddress: args['dropAddress'] as String? ?? '',
              totalDistance: (args['totalDistance'] as num?)?.toDouble() ?? 0,
              totalCost: (args['totalCost'] as num?)?.toDouble() ?? 0,
              vehicleTypeName: args['vehicleTypeName'] as String?,
            ),
          );
        }
        return _errorRoute('Active ride data is missing');

      case rideRequests:
        return MaterialPageRoute(
          builder: (_) => const RideRequestsScreen(),
          settings: settings,
        );

      case manageVehicleProfiles:
        return MaterialPageRoute(builder: (_) => const ManageVehicleProfilesScreen());

      case passengerTracking:
        final args = settings.arguments;
        if (args is! PassengerTrackingArgs) {
          return _errorRoute('Passenger tracking data is missing');
        }
        return MaterialPageRoute(
          builder: (_) => PassengerTrackingScreen(args: args),
        );

      // ─── Payment Routes ──────────────────────────────────────────
      case paymentMethods:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentMethodsScreen(
              userId: args['userId'] as int,
              firstName: args['firstName'] as String? ?? '',
              lastName: args['lastName'] as String? ?? '',
              email: args['email'] as String? ?? '',
              phone: args['phone'] as String? ?? '',
            ),
          );
        }
        return _errorRoute('Payment methods data is missing');

      case paymentHistory:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PaymentHistoryScreen(
              userId: args['userId'] as int,
            ),
          );
        }
        return _errorRoute('Payment history data is missing');

      case driverWallet:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => DriverWalletScreen(
              driverProfileId: args['driverProfileId'] as int,
            ),
          );
        }
        return _errorRoute('Driver wallet data is missing');

      case withdrawalRequest:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => WithdrawalRequestScreen(
              driverProfileId: args['driverProfileId'] as int,
              availableBalance:
                  (args['availableBalance'] as num?)?.toDouble() ?? 0,
              currency: args['currency'] as String? ?? 'LKR',
            ),
          );
        }
        return _errorRoute('Withdrawal request data is missing');

      case withdrawalHistory:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => WithdrawalHistoryScreen(
              driverProfileId: args['driverProfileId'] as int,
            ),
          );
        }
        return _errorRoute('Withdrawal history data is missing');

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
