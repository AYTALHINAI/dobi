import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // TOP GRADIENT LIKE FORGOT PASSWORD PAGE
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A85B6), // Soft blue
                  Color(0xFFBAC8E0), // Lighter blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // HEADER SECTION
                Container(
                  height: screenHeight * 0.25,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black87, size: 26),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                        ),
                      ),

                      const Spacer(),

                      // Logo Text (unchanged)
                      Center(
                        child: Text(
                          'DOBBIE',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(2, 3),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // WHITE CURVED FORM SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        "Choose registration type",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // USER CARD
                      _buildCard(
                        icon: Icons.person,
                        title: "Register as User",
                        subtitle: "Create a normal user account to request deliveries.",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.userRegisterStep1);
                        },
                      ),
                      const SizedBox(height: 25),

                      // DRIVER CARD
                      _buildCard(
                        icon: Icons.local_shipping,
                        title: "Register as Driver",
                        subtitle: "Become a delivery driver and start earning.",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.driverRegisterStep1);
                        },
                      ),
                      const SizedBox(height: 25),

                      // SHOP OWNER CARD
                      _buildCard(
                        icon: Icons.storefront,
                        title: "Register as Shop Owner",
                        subtitle: "Create an account to sell your products on the platform.",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.shopOwnerStep1);
                        },
                      ),
                      const SizedBox(height: 30), // extra spacing at bottom
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // CARD WIDGET MATCHING FORGOT PASSWORD STYLE
  // -----------------------------
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey.shade100, // lighter grey like Forgot Password inputs
        elevation: 5,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.indigo.shade700),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
