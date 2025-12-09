import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey.shade300.withOpacity(0.9),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // TOP SECTION ----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Dobi Logo',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN CONTAINER -------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
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
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // USER CARD -------------------------------------------------
                      _buildCard(
                        icon: Icons.person,
                        title: "Register as User",
                        subtitle: "Create a normal user account to request deliveries.",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.userRegisterStep1);
                        },
                      ),

                      const SizedBox(height: 25),

                      // DRIVER CARD -----------------------------------------------
                      _buildCard(
                        icon: Icons.local_shipping,
                        title: "Register as Driver",
                        subtitle: "Become a delivery driver and start earning.",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.driverRegisterStep1);
                        },
                      ),

                      const SizedBox(height: 25),

                      // SHOP OWNER CARD -------------------------------------------
                      _buildCard(
                        icon: Icons.storefront,
                        title: "Register as Shop Owner",
                        subtitle: "Create an account to sell your products on the platform.",
                        onTap: () {
                          // Navigator.pushNamed(context, AppRoutes.shopRegisterStep1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // CARD WIDGET (clean reusable)
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
        color: Colors.grey.shade200,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.black87),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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
