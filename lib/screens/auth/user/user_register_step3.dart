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
          Container(color: Colors.grey.shade300.withOpacity(0.9)),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // Top section with back button & step info
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Step 3: Confirm Information",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Submit to complete registration",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form container (no validation required for optional fields)
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: _btnStyle(Colors.grey.shade400),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Back", style: TextStyle(fontSize: 16, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: _btnStyle(Colors.black87),
                                  onPressed: () async {
                                    final dbService = DatabaseService();
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                    );

                                    // Register user - optional fields are allowed to be empty
                                    String? error = await dbService.registerUser(widget.data);
                                    Navigator.pop(context);

                                    if (error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error: $error")),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Registration Complete!")),
                                      );

                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.userHome,
                                            (route) => false,
                                      );
                                    }
                                  },
                                  child: const Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white)),
                                ),
                              ),
                            ],
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
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          Expanded(
            child: Text(value.isEmpty ? "-" : value, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
