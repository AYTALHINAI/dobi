import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import 'user_registration_model.dart';
import '../../widgets/step_tracker_bar.dart';
import '../../../database.dart';

class UserRegisterStep3 extends StatefulWidget {
  final UserRegistrationData data;

  const UserRegisterStep3({super.key, required this.data});

  @override
  State<UserRegisterStep3> createState() => _UserRegisterStep3State();
}

class _UserRegisterStep3State extends State<UserRegisterStep3> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient top section like Step 1 & 2
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A85B6),
                  Color(0xFFBAC8E0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // Top header section with back icon
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
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Step 3: Confirm Information",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Submit to complete registration",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White curved form/info container
                  Expanded(
                    child: Container(
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
                          StepTrackerBar(currentStep: 3, totalSteps: 3),
                          const SizedBox(height: 24),
                          const Text(
                            "Review your information before submitting:",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow("Full Name", widget.data.fullName),
                          _buildInfoRow("Phone Number", widget.data.phone),
                          _buildInfoRow("Email", widget.data.email),
                          _buildInfoRow("Address", widget.data.address),
                          _buildInfoRow("City", widget.data.city),
                          _buildInfoRow("Postal Code", widget.data.postalCode),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: _btnStyle(Colors.indigo.shade700),
                              onPressed: () async {
                                final dbService = DatabaseService();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                  const Center(child: CircularProgressIndicator()),
                                );

                                String? error = await dbService.registerUser(widget.data);
                                Navigator.pop(context);

                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $error")),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Registration Complete!")),
                                  );

                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.userHome,
                                        (route) => false,
                                  );
                                }
                              },
                              child: const Text(
                                "Submit",
                                style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label: ",
              style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          Expanded(
            child: Text(value.isEmpty ? "-" : value,
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
