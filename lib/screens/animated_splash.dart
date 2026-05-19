import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dobi/routes/app_routes.dart';
import 'package:dobi/database.dart';
import 'package:dobi/screens/auth/welcome.dart';

class CustomSplashScreen extends StatelessWidget {
  const CustomSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset('assets/Welcome.json', height: 250, width: 250),
      ),
      splashIconSize: 300,
      nextScreen: const AuthSessionWrapper(),
      splashTransition: SplashTransition.fadeTransition,
      duration: 7500,
      backgroundColor: Colors.white,
    );
  }
}

class AuthSessionWrapper extends StatefulWidget {
  const AuthSessionWrapper({super.key});

  @override
  State<AuthSessionWrapper> createState() => _AuthSessionWrapperState();
}

class _AuthSessionWrapperState extends State<AuthSessionWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkSession();
    });
  }

  Future<void> _checkSession() async {
    // Wait for the splash screen's transition animation to complete
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
      return;
    }

    try {
      final db = DatabaseService();
      final role = await db.getUserRole(user.uid);
      if (!mounted) return;

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      } else if (role == "driver") {
        Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
      } else if (role == "shopOwner") {
        final status = await db.getShopOwnerStatus(user.email ?? '');
        if (!mounted) return;
        if (status == "approved") {
          Navigator.pushReplacementNamed(context, AppRoutes.shopOwnerHome);
        } else {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        }
      } else if (role == "user") {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      } else {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    } catch (_) {
      if (mounted) {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5C6BC0),
        ),
      ),
    );
  }
}