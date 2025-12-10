import 'package:flutter/material.dart';

// AUTH SCREENS
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forgot_password_page.dart';
import '../screens/auth/otp_verification_page.dart';

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
import '../screens/shopOwner/shopOwner_home_page.dart'; // <- Import ShopOwnerHomePage

// SHOP OWNER REGISTRATION STEPS
import '../screens/auth/shopOwner/Shop_Owner_Registration_Step1.dart';
import '../screens/auth/shopOwner/Shop_Info_step2.dart';
import '../screens/auth/shopOwner/Terms_&_Agreement_step3.dart';
import '../screens/auth/shopOwner/shop_owner_registration_model.dart';

// ADMIN DRIVER APPLICANTS
import '../screens/admin/driverApplicants/DriverApplicantDetailPage.dart';
import '../screens/admin/driverApplicants/DriverApplicantsPage.dart';

// ADMIN SHOP OWNER APPLICANTS
import '../screens/admin/shopOwners/ShopOwnerApplicantsPage.dart';
import '../screens/admin/shopOwners/ShopOwnerApplicantDetailPage.dart';

class AppRoutes {
  // AUTH
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';

  // USER REGISTRATION MULTI-STEP
  static const String userRegisterStep1 = '/register/user/step1';
  static const String userRegisterStep2 = '/register/user/step2';
  static const String userRegisterStep3 = '/register/user/step3';

  // DRIVER REGISTRATION MULTI-STEP
  static const String driverRegisterStep1 = '/register/driver/step1';
  static const String driverRegisterStep2 = '/register/driver/step2';
  static const String driverRegisterStep3 = '/register/driver/step3';

  // SHOP OWNER REGISTRATION MULTI-STEP
  static const String shopOwnerStep1 = '/register/shopOwner/step1';
  static const String shopOwnerStep2 = '/register/shopOwner/step2';
  static const String shopOwnerStep3 = '/register/shopOwner/step3';

  // HOME PAGES
  static const String adminHome = '/home/admin';
  static const String userHome = '/home/user';
  static const String driverHome = '/home/driver';
  static const String shopOwnerHome = '/home/shop-owner';

  // ADMIN PAGES
  static const String adminDriverApplicants = '/admin/drivers';
  static const String adminDriverDetail = '/admin/driver-detail';
  static const String adminShopOwnerApplicants = '/admin/shop-owners';
  static const String adminShopOwnerDetail = '/admin/shop-owner-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // AUTH
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case otpVerification:
        final email = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email));

    // USER REGISTRATION
      case userRegisterStep1:
        return MaterialPageRoute(builder: (_) => const UserRegisterStep1());
      case userRegisterStep2:
        final userData = settings.arguments as UserRegistrationData;
        return MaterialPageRoute(builder: (_) => UserRegisterStep2(data: userData));
      case userRegisterStep3:
        final userData = settings.arguments as UserRegistrationData;
        return MaterialPageRoute(builder: (_) => UserRegisterStep3(data: userData));

    // DRIVER REGISTRATION
      case driverRegisterStep1:
        return MaterialPageRoute(builder: (_) => const DriverStep1Basic());
      case driverRegisterStep2:
        final driverData = settings.arguments as DriverRegistrationData;
        return MaterialPageRoute(builder: (_) => DriverStep2Vehicle(data: driverData));
      case driverRegisterStep3:
        final driverData = settings.arguments as DriverRegistrationData;
        return MaterialPageRoute(builder: (_) => DriverStep3License(data: driverData));

    // SHOP OWNER REGISTRATION
      case shopOwnerStep1:
        return MaterialPageRoute(builder: (_) => const ShopOwnerStep1Personal());
      case shopOwnerStep2:
        final shopOwnerData = settings.arguments as ShopOwnerRegistrationData;
        return MaterialPageRoute(builder: (_) => ShopOwnerStep2ShopInfo(data: shopOwnerData));
      case shopOwnerStep3:
        final shopOwnerData = settings.arguments as ShopOwnerRegistrationData;
        return MaterialPageRoute(builder: (_) => ShopOwnerStep3Terms(data: shopOwnerData));

    // ADMIN DRIVER PAGES
      case adminDriverApplicants:
        return MaterialPageRoute(builder: (_) => const DriverApplicantsPage());
      case adminDriverDetail:
        final driverData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => DriverApplicantDetailPage(driverData: driverData));

    // ADMIN SHOP OWNER PAGES
      case adminShopOwnerApplicants:
        return MaterialPageRoute(builder: (_) => const ShopOwnerApplicantsPage());
      case adminShopOwnerDetail:
        final ownerData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ShopOwnerApplicantDetailPage(ownerData: ownerData));

    // HOME PAGES
      case adminHome:
        return MaterialPageRoute(builder: (_) => AdminHomePage());
      case userHome:
        return MaterialPageRoute(builder: (_) => UserHomePage());
      case driverHome:
        return MaterialPageRoute(builder: (_) => DriverHomePage());
      case shopOwnerHome:
        return MaterialPageRoute(builder: (_) => const ShopOwnerHomePage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
