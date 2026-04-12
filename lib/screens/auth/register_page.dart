import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final DatabaseService _dbService = DatabaseService();
  bool _isGoogleLoading = false;

  void _showNotification(String message, {Color color = Colors.red}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _dbService.signInWithGoogle();
      if (!mounted) return;
      if (result == 'new') {
        Navigator.pushReplacementNamed(context, AppRoutes.userPersonalInfoSetup);
      } else {
        // User already has an account — go straight home
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      }
    } catch (e) {
      String message = e.toString().replaceAll('Exception:', '').trim();
      if (message != 'Google sign-in was cancelled.') {
        _showNotification(message);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Premium Color Palette
    const Color primaryDeep = Color(0xFF1A237E); // Deep Indigo
    const Color primaryLight = Color(0xFF3949AB); // Lighter Indigo

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDeep, primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // HEADER AREA
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'DOBBIE',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 31),

                    // WHITE CARD CONTENT
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(28, 40, 28, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Let's Get Started",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Choose your account type below",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // USER CARD
                            _buildCard(
                              icon: Icons.person_outline_rounded,
                              title: "User",
                              subtitle: "I want to request laundry services",
                              color: Colors.blue.shade50,
                              iconColor: Colors.blue.shade700,
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.userRegisterStep1);
                              },
                            ),

                            // GOOGLE SIGN-UP — Customer only
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: _isGoogleLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.blueGrey.shade700,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/google.png',
                                            height: 20,
                                            width: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Sign up as User with Google',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // DRIVER CARD
                            _buildCard(
                              icon: Icons.local_shipping_outlined,
                              title: "Driver",
                              subtitle: "I want to deliver packages",
                              color: Colors.blue.shade50,
                              iconColor: Colors.blue.shade700,
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.driverRegisterStep1);
                              },
                            ),
                            const SizedBox(height: 16),

                            // SHOP OWNER CARD
                            _buildCard(
                              icon: Icons.storefront_outlined,
                              title: "Shop Owner",
                              subtitle: "I want to sell my products",
                              color: Colors.blue.shade50,
                              iconColor: Colors.blue.shade700,
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.shopRegisterStep1);
                              },
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // PREMIUM CARD WIDGET
  // -----------------------------
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
