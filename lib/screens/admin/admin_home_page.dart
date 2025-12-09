import 'package:flutter/material.dart';
import '../../routes/app_routes.dart'; // make sure your routes file is imported

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes back arrow
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // You can also add a confirmation dialog if you want
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Example buttons for admin actions
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to driver applicants page
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
                foregroundColor: Colors.black, // makes the text and icon black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // You can add more admin actions here later
          ],
        ),
      ),
    );
  }
}
