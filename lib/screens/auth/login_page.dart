import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseService dbService = DatabaseService();

  bool isLoading = false;
  bool showPassword = false; // toggle password

  void showNotification(String message, {Color color = Colors.red}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      String role = await dbService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      } else if (role == "driver") {
        Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      }

      showNotification("Login successful!", color: Colors.green);
    } catch (e) {
      showNotification(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Optional overlay (grey shades instead of purple)
          Container(
            color: Colors.grey.shade300.withOpacity(0.9),
          ),

          // Main Content
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight, // occupy full screen
              child: Column(
                children: [
                  // Top Logo Placeholder
                  Container(
                    height: screenHeight * 0.25,
                    alignment: Alignment.center,
                    child: const Text(
                      'Dobbie Logo',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Login Form expanded to fill rest
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
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),

                            // Email Field
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email, color: Colors.grey.shade700),
                                hintText: 'Email',
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your email.";
                                }
                                final validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                                if (!validEmail) {
                                  return "Please enter a valid email address.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field with toggle
                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: Colors.grey.shade700),
                                hintText: 'Password',
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your password.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 35),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  backgroundColor: Colors.black87,
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                  'Login',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Forgot Password & Register Links
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.register);
                                  },
                                  child: Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const SizedBox(height: 20),

                            // Divider with text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade400,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'or sign in with',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade400,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // Social login buttons (non-functional for now)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Google
                                Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/google.png', // add your logo here
                                      height: 50,
                                      width: 50,
                                    ),
                                  ),
                                ),
                                // Facebook
                                Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/Facebook.png', // add your logo here
                                      height: 68,
                                      width: 68,
                                    ),
                                  ),
                                ),
                              ],
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
}
