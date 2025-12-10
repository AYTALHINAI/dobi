import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/step_tracker_bar.dart';
import 'driver_registration_model.dart';

class DriverStep1Basic extends StatefulWidget {
  const DriverStep1Basic({super.key});

  @override
  State<DriverStep1Basic> createState() => _DriverStep1BasicState();
}

class _DriverStep1BasicState extends State<DriverStep1Basic> {
  final _formKey = GlobalKey<FormState>();
  final DriverRegistrationData data = DriverRegistrationData();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey.shade300.withOpacity(0.9)),

          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.register);
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              "Step 1: Personal Information",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Next: Vehicle Details",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StepTrackerBar(currentStep: 1, totalSteps: 3),
                        const SizedBox(height: 24),

                        _buildField(nameController, "Full Name"),
                        const SizedBox(height: 16),

                        _buildField(phoneController, "Phone Number", keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),

                        _buildField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),

                        _buildField(passwordController, "Password", obscureText: true),
                        // Password requirement box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your password must contain:",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text("• Minimum 6 characters", style: TextStyle(fontSize: 12)),
                              Text("• At least 1 uppercase letter (A–Z)", style: TextStyle(fontSize: 12)),
                              Text("• At least 1 lowercase letter (a–z)", style: TextStyle(fontSize: 12)),
                              Text("• At least 1 number (0–9)", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildField(confirmPasswordController, "Confirm Password", obscureText: true),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                data.fullName = nameController.text;
                                data.phone = phoneController.text;
                                data.email = emailController.text;
                                data.password = passwordController.text;

                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.driverRegisterStep2,
                                  arguments: data,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Next",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30), // extra bottom spacing to prevent overflow
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),

      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Enter $label";

        if (label == "Full Name") {
          if (v.trim().length < 3) return "Name must be at least 3 characters";
          if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
            return "Name can contain letters only";
          }
        }

        if (label == "Phone Number") {
          if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
            return "Phone must contain numbers only";
          }
          if (v.length != 8) return "Phone number must be exactly 8 digits";
          if (!v.startsWith('7') && !v.startsWith('9')) {
            return "Phone number must start with 7 or 9";
          }
        }

        if (label == "Email") {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
            return "Enter a valid email";
          }
        }

        if (label == "Password") {
          if (v.length < 6) return "Min 6 characters";
          if (!RegExp(r'[A-Z]').hasMatch(v)) return "Must contain an uppercase letter";
          if (!RegExp(r'[a-z]').hasMatch(v)) return "Must contain a lowercase letter";
          if (!RegExp(r'[0-9]').hasMatch(v)) return "Must contain a number";
        }

        if (label == "Confirm Password") {
          if (v != passwordController.text) return "Passwords do not match";
        }

        return null;
      },
    );
  }
}
