import 'package:flutter/material.dart';

// AUTH SCREENS
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forgot_password_page.dart';

// USER REGISTRATION STEPS
import '../screens/auth/user/user_register_step1.dart';
import '../screens/auth/user/user_register_step2.dart';
import '../screens/auth/user/user_register_step3.dart';
import '../screens/auth/user/user_registration_model.dart';

// DRIVER REGISTRATION STEPS
import '../screens/auth/driver/driver_step1_basic.dart';
import '../screens/auth/driver/driver_step2_vehicle.dart';
import '../screens/auth/driver/driver_step3_license.dart';
import '../screens/auth/driver/driver_registration_model.dart';

// HOME PAGES
import '../screens/admin/admin_home_page.dart';
import '../screens/user/user_home_page.dart';
import '../screens/driver/driver_home_page.dart';

class AppRoutes {
  // AUTH
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // USER REGISTRATION MULTI-STEP
  static const String userRegisterStep1 = '/register/user/step1';
  static const String userRegisterStep2 = '/register/user/step2';
  static const String userRegisterStep3 = '/register/user/step3';

  // DRIVER REGISTRATION MULTI-STEP
  static const String driverRegisterStep1 = '/register/driver/step1';
  static const String driverRegisterStep2 = '/register/driver/step2';
  static const String driverRegisterStep3 = '/register/driver/step3';

  // HOME PAGES
  static const String adminHome = '/home/admin';
  static const String userHome = '/home/user';
  static const String driverHome = '/home/driver';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // AUTH
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());

    // USER REGISTRATION
      case userRegisterStep1:
        return MaterialPageRoute(builder: (_) => const UserRegisterStep1());
      case userRegisterStep2:
        final userData = settings.arguments as UserRegistrationData;
        return MaterialPageRoute(
            builder: (_) => UserRegisterStep2(data: userData));
      case userRegisterStep3:
        final userData = settings.arguments as UserRegistrationData;
        return MaterialPageRoute(
            builder: (_) => UserRegisterStep3(data: userData));

    // DRIVER REGISTRATION
      case driverRegisterStep1:
        return MaterialPageRoute(builder: (_) => const DriverStep1Basic());
      case driverRegisterStep2:
        final driverData = settings.arguments as DriverRegistrationData;
        return MaterialPageRoute(
            builder: (_) => DriverStep2Vehicle(data: driverData));
      case driverRegisterStep3:
        final driverData = settings.arguments as DriverRegistrationData;
        return MaterialPageRoute(
            builder: (_) => DriverStep3License(data: driverData));


    // HOME PAGES
      case adminHome:
        return MaterialPageRoute(builder: (_) =>  AdminHomePage());
      case userHome:
        return MaterialPageRoute(builder: (_) =>  UserHomePage());
      case driverHome:
        return MaterialPageRoute(builder: (_) =>  DriverHomePage());

      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ));
    }
  }
}
