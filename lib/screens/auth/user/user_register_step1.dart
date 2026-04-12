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
    // Using simple size to avoid complex rebuilds
    final size = MediaQuery.of(context).size;

    // Premium Color Palette
    const Color primaryDeep = Color(0xFF1A237E); // Deep Indigo
    const Color primaryLight = Color(0xFF3949AB); // Lighter Indigo
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDeep, primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          
          // Decorative Circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // HEADER AREA
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  Navigator.pushReplacementNamed(context, AppRoutes.register);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Step 1',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            'Personal Info',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // WHITE CARD CONTENT
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StepTrackerBar(
                                currentStep: 1, 
                                totalSteps: 3,
                                stepLabels: ['Personal', 'Address', 'Confirm'],
                              ),
                              const SizedBox(height: 24),

                              _buildTextField(nameController, "Full Name", Icons.person_outline),
                              const SizedBox(height: 16),

                              _buildTextField(
                                phoneController,
                                "Phone Number",
                                Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                emailController,
                                "Email",
                                Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                passwordController,
                                "Password",
                                Icons.lock_outline,
                                obscureText: true,
                              ),

                              // PASSWORD REQUIREMENTS
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Password Requirements:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildReqText("Minimum 6 characters"),
                                    _buildReqText("At least 1 uppercase (A-Z)"),
                                    _buildReqText("At least 1 lowercase (a-z)"),
                                    _buildReqText("At least 1 number (0-9)"),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                confirmPasswordController,
                                "Confirm Password",
                                Icons.lock_reset_outlined,
                                obscureText: true,
                              ),

                              const SizedBox(height: 35),

                              // NEXT BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      data.fullName = nameController.text.trim();
                                      data.phone = phoneController.text.trim();
                                      data.email = emailController.text.trim();
                                      data.password = passwordController.text;

                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.userRegisterStep2,
                                        arguments: data,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDeep,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: primaryDeep.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'NEXT STEPS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
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
    );
  }

  Widget _buildReqText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "• $text",
        style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    const primaryDeep = Color(0xFF1A237E);
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF5C6BC0)),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryDeep, width: 1.5),
        ),
      ),
    );
  }
}
