import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../../../database.dart';
import '../../widgets/step_tracker_bar.dart';
import 'shop_owner_registration_model.dart'; // Corrected Import
import 'package:firebase_auth/firebase_auth.dart';

class ShopOwnerStep3Terms extends StatefulWidget {
  final ShopOwnerRegistrationData data;
  const ShopOwnerStep3Terms({super.key, required this.data});

  @override
  State<ShopOwnerStep3Terms> createState() => _ShopOwnerStep3TermsState();
}

class _ShopOwnerStep3TermsState extends State<ShopOwnerStep3Terms> {
  bool isAgreed = false;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color primaryDeep = Color(0xFF1A237E);
    const Color primaryLight = Color(0xFF3949AB);

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
                              radius: 22,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.shopRegisterStep2, // Updated Route Name
                                    arguments: widget.data,
                                  );
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
                            Icons.article_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Step 3',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            'Terms & Confirm',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StepTrackerBar(
                              currentStep: 3, 
                              totalSteps: 3,
                              stepLabels: ['Personal', 'Shop Details', 'Terms'],
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              "Terms and Agreement",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryDeep,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Terms Box
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const SingleChildScrollView(
                                child: Text(
                                  "1. Shop Ownership Verification: You must provide valid proof of shop ownership upon request.\n\n"
                                  "2. Service Standards: You agree to maintain high service quality for Dobi users and adhere to platform pricing guidelines.\n\n"
                                  "3. Payments: Dobi takes a commission on orders processed through the platform. Payouts are processed weekly.\n\n"
                                  "4. Liability: You are responsible for the items in your care. Any damage or loss must be compensated as per the refund policy.\n\n"
                                  "5. Termination: Dobi reserves the right to suspend accounts that violate these terms or receive consistent complaints.",
                                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: isAgreed,
                                  activeColor: primaryDeep,
                                  onChanged: (val) {
                                    setState(() => isAgreed = val ?? false);
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    "I agree to the Terms & Conditions",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: (isAgreed && !isSubmitting) ? _submitRegistration : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryDeep,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  elevation: 8,
                                  shadowColor: primaryDeep.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'REGISTER SHOP',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegistration() async {
    setState(() => isSubmitting = true);
    final dbService = DatabaseService();

    try {
      // 1. Create Auth User
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.data.email!,
        password: widget.data.password!,
      );

      // 2. Save additional data to Firestore
      String uid = userCredential.user!.uid;
      // Fixed: changed createShopOwner to registerShopOwner as defined in DatabaseService
      await dbService.registerShopOwner(widget.data); // Corrected Method Call

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shop Owner Registration Complete!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Home or Login
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration Failed"), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}
