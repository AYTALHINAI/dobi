import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; 

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Driver Applicants Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.adminDriverApplicants);
              },
              icon: const Icon(Icons.drive_eta, color: Colors.black),
              label: const Text(
                'View Driver Applicants',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.white10,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Shop Owner Applicants Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.adminShopOwnerApplicants);
              },
              icon: const Icon(Icons.store, color: Colors.black),
              label: const Text(
                'View Shop Owner Applicants',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.white10,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: GNav(
          color: Colors.blue,
          activeColor: Colors.blue,
          tabBackgroundColor: Colors.blue.shade100,
          gap: 8,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          mainAxisAlignment: MainAxisAlignment.center,
          tabs: const [
            GButton(
              icon: Icons.drive_eta,
              text: "Driver Applicants",
            ),
            GButton(
              icon: Icons.shopping_bag_rounded,
              text: "Shop Owner Applicants",
            ),
          ],
        ),
      ),
    );
  }
}