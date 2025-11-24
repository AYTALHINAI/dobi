// lib/screens/auth/user/user_register_step1.dart
import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import 'user_registration_model.dart';
import '../../widgets/step_tracker_bar.dart';

class UserRegisterStep1 extends StatefulWidget {
  const UserRegisterStep1({super.key});

  @override
  State<UserRegisterStep1> createState() => _UserRegisterStep1State();
}

class _UserRegisterStep1State extends State<UserRegisterStep1> {
  final _formKey = GlobalKey<FormState>();
  final UserRegistrationData data = UserRegistrationData();

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Grey background
          Container(
            color: Colors.grey.shade300.withOpacity(0.9),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // Top section with back button and step info
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back arrow top-left
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.register);
                          },
                        ),

                        const Spacer(),

                        // Step info centered
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
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Next: Location Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main form container
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            StepTrackerBar(currentStep: 1, totalSteps: 3),
                            const SizedBox(height: 24),
                            _buildTextField(nameController, "Full Name"),
                            const SizedBox(height: 16),
                            _buildTextField(phoneController, "Phone Number", keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildTextField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildTextField(passwordController, "Password", obscureText: true),
                            const SizedBox(height: 16),
                            _buildTextField(confirmPasswordController, "Confirm Password", obscureText: true),
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
                                      AppRoutes.userRegisterStep2,
                                      arguments: data,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: const Text(
                                  "Next",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Enter $label";
        if (label == "Email" && !v.contains("@")) return "Enter a valid email";
        if (label == "Confirm Password" && v != passwordController.text) return "Passwords do not match";
        if (label == "Password" && v.length < 6) return "Min 6 characters";
        return null;
      },
    );
  }
}
