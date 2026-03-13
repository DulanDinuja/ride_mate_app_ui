import 'user_role.dart';

class UserRegistrationRequest {
  final String email;
  final String phoneNumber;
  final String password;
  final UserRole userRole;
  final String firstName;
  final String lastName;

  UserRegistrationRequest({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.userRole,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'userRole': userRole.name,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}
