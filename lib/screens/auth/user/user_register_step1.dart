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
          // TOP GRADIENT LIKE FORGOT PASSWORD
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
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // HEADER SECTION WITH GRADIENT
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
                              Navigator.pushReplacementNamed(context, AppRoutes.register);
                            },
                          ),
                        ),

                        const Spacer(),

                        // ORIGINAL TOP TEXT RESTORED
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Step 1: Personal Information",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Next: Location Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // WHITE CURVED FORM SECTION
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
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

                              _buildTextField(
                                phoneController,
                                "Phone Number",
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                emailController,
                                "Email",
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                passwordController,
                                "Password",
                                obscureText: true,
                              ),

                              // PASSWORD REQUIREMENT BOX
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Your password must contain:",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text("• Minimum 6 characters",
                                        style: TextStyle(fontSize: 14, height: 1.4)),
                                    Text("• At least 1 uppercase letter (A–Z)",
                                        style: TextStyle(fontSize: 14, height: 1.4)),
                                    Text("• At least 1 lowercase letter (a–z)",
                                        style: TextStyle(fontSize: 14, height: 1.4)),
                                    Text("• At least 1 number (0–9)",
                                        style: TextStyle(fontSize: 14, height: 1.4)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                confirmPasswordController,
                                "Confirm Password",
                                obscureText: true,
                              ),

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
                                    backgroundColor: Colors.indigo.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Next",
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
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

  // INPUT FIELD BUILDER MATCHING FORGOT PASSWORD STYLE
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
      ),

      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Enter $label";

        if (label == "Full Name") {
          if (v.trim().length < 3) return "Name must be at least 3 characters";
          if (!RegExp(r"^[a-zA-Z ]+$").hasMatch(v.trim())) {
            return "Name can contain letters only";
          }
        }

        if (label == "Phone Number") {
          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return "Phone must contain numbers only";
          if (v.length != 8) return "Phone number must be exactly 8 digits";
          if (!v.startsWith('9') && !v.startsWith('7')) {
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
