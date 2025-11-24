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
          // Background shade
          Container(
            color: Colors.grey.shade300.withOpacity(0.9),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // Top Logo Placeholder with back button
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back arrow at top left
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.login);
                          },
                        ),

                        const Spacer(),

                        // Logo centered horizontally
                        Center(
                          child: const Text(
                            'Dobi Logo',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content container
                  Expanded(
                    child: Container(
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // ----------------------------
                          // Register as USER
                          // ----------------------------
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.userRegisterStep1);
                            },
                            child: Card(
                              color: Colors.grey.shade200, // changed from purple to light grey
                              elevation: 4,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 30, horizontal: 20),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Icon(Icons.person, size: 48, color: Colors.black87),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Register as User",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Create a normal user account to request deliveries.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 35),

                          // ----------------------------
                          // Register as DRIVER
                          // ----------------------------
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.driverRegisterStep1);
                            },
                            child: Card(
                              color: Colors.grey.shade200, // changed from purple to light grey
                              elevation: 4,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 30, horizontal: 20),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Icon(Icons.local_shipping,
                                        size: 48, color: Colors.black87),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Register as Driver",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Become a delivery driver and start earning.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
