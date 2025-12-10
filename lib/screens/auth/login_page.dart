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
  bool showPassword = false;

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
      } else if (role == "shopOwner") {
        String status = await dbService.getShopOwnerStatus(emailController.text.trim());

        if (status == "approved") {
          Navigator.pushReplacementNamed(context, AppRoutes.shopOwnerHome);
        } else if (status == "pending") {
          showNotification("Your application is under review.", color: Colors.orange);
        } else if (status == "rejected") {
          showNotification("Your application was rejected.", color: Colors.red);
        } else {
          showNotification("Unknown status. Contact support.");
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      }

      if (role == "admin" ||
          role == "driver" ||
          (role == "shopOwner" &&
              await dbService.getShopOwnerStatus(emailController.text.trim()) == "approved")) {
        showNotification("Login successful!", color: Colors.green);
      }
    } catch (e) {
      String message = e.toString().replaceAll("Exception:", "").trim();
      showNotification(message);
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
          // ✨ Modern Gradient Background
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
                  // 🎉 Improved Branding Area
                  Container(
                    height: screenHeight * 0.25,
                    alignment: Alignment.center,
                    child: Text(
                      'DOBBIE',
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(2, 3),
                          )
                        ],
                      ),
                    ),
                  ),

                  // White curved container (unchanged structure)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.98),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),

                            const SizedBox(height: 34),

                            // ✨ Updated TextField Style
                            TextFormField(
                              controller: emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Enter your email";
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email, color: Colors.indigo.shade400),
                                hintText: 'Email',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.indigo.shade100),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Enter your password";
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock, color: Colors.indigo.shade400),
                                hintText: 'Password',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.indigo.shade100),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.indigo.shade400,
                                  ),
                                  onPressed: () =>
                                      setState(() => showPassword = !showPassword),
                                ),
                              ),
                            ),

                            const SizedBox(height: 35),

                            // ✨ Modern Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.indigo.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.indigo.shade200,
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Footer buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Colors.indigo.shade700),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                                  child: Text(
                                    "Register",
                                    style: TextStyle(color: Colors.indigo.shade700),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
