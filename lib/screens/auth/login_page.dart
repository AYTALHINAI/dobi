import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();


}
// ------------------ Validators ------------------
class LoginValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Enter your email";
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return "Enter a valid email";
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Enter your password";
    return null;
  }
}
// ---------------------------------------------------------------------------

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



  Future<void> loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final result = await dbService.signInWithGoogle();
      if (!mounted) return;
      if (result == 'new') {
        Navigator.pushReplacementNamed(context, AppRoutes.userPersonalInfoSetup);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      }
    } catch (e) {
      String message = e.toString().replaceAll('Exception:', '').trim();
      if (message != 'Google sign-in was cancelled.') {
        showNotification(message);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
    // Using simple size to avoid complex rebuilds/focus loss
    final size = MediaQuery.of(context).size;

    // Premium Color Palette
    const Color primaryDeep = Color(0xFFFFFFFF); // Deep Indigo
    const Color primaryLight = Color(0xFFFFFFFF); // Lighter Indigo
    const Color accentColor = Color(0xFF5C6BC0);

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
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
                              radius: 22,
                              backgroundColor: Colors.black.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // LOGO AREA
                    SizedBox(height: size.height * 0.01), // Top spacing
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo_horizon.png',
                            width: size.width * 0.7,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // LOGIN FORM CARD
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    "or ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                                    child: Text(
                                      "Join Dobbie",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // EMAIL
                              TextFormField(
                                controller: emailController,
                                validator: LoginValidators.validateEmail,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined, color: accentColor),
                                  hintText: 'Email Address',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                                    borderSide: BorderSide(color: accentColor, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD
                              TextFormField(
                                controller: passwordController,
                                obscureText: !showPassword,
                                validator: LoginValidators.validatePassword,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: accentColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () => setState(() => showPassword = !showPassword),
                                  ),
                                  hintText: 'Password',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                                    borderSide: BorderSide(color: accentColor, width: 1.5),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // FORGOT PASSWORD
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                                  style: TextButton.styleFrom(
                                    foregroundColor: accentColor,
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // LOGIN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3F37C9),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: primaryDeep.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                      : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // OR DIVIDER
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade400,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // GOOGLE SIGN-IN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : loginWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/google.png',
                                        height: 22,
                                        width: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              const SizedBox(height: 8),
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
}
