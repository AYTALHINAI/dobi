import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../database.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final DatabaseService dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  void showNotification(String message, {Color color = Colors.green}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String result =
      await dbService.sendPasswordResetEmail(emailController.text.trim());
      showNotification(result, color: Colors.green);
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      showNotification(e.toString(), color: Colors.red);
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
          // SAME GRADIENT AS LOGIN PAGE
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
                  // Top header identical to login page style
                  Container(
                    height: screenHeight * 0.25,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black87, size: 26),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.login);
                            },
                          ),
                        ),

                        const Spacer(),

                        // SAME DOBBIE STYLE AS LOGIN PAGE
                        Center(
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
                      ],
                    ),
                  ),

                  // Bottom white curved section (unchanged)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
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
                            const SizedBox(height: 22),

                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Forgot Password',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),

                            const SizedBox(height: 34),

                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email,
                                    color: Colors.indigo.shade400),
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
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
                                    borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your email.";
                                }
                                final validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value.trim());
                                if (!validEmail) {
                                  return "Please enter a valid email address.";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 35),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : sendResetLink,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  backgroundColor: Colors.indigo.shade700,
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                    color: Colors.white)
                                    : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.pushReplacementNamed(
                            //         context, AppRoutes.login);
                            //   },
                            //   child: Text(
                            //     "Back to Login",
                            //     style: TextStyle(
                            //       fontSize: 16,
                            //       color: Colors.indigo.shade700,
                            //       fontWeight: FontWeight.w600,
                            //     ),
                            //   ),
                            // ),

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
