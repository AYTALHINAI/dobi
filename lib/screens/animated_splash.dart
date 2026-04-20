import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:dobi/routes/app_routes.dart';
import 'package:dobi/screens/auth/login_page.dart';

class CustomSplashScreen extends StatelessWidget {
  const CustomSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
        splash: Center(
          child: Lottie.asset('assets/Welcome.json',height: 250,width: 250),
        ),
      splashIconSize: 300,
      nextScreen: const LoginPage(),
      splashTransition: SplashTransition.fadeTransition,
      duration: 7500,
      backgroundColor: Colors.white,
     
    );
  }
}