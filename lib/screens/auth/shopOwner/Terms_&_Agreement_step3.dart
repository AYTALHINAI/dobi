import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../../../database.dart';
import '../../widgets/step_tracker_bar.dart';
import 'shop_owner_registration_model.dart';

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
    const Color primaryDeep = Color(0xFFFFFFFF);
    const Color primaryLight = Color(0xFFFFFFFF);

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
                              backgroundColor: Colors.black.withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.grey, size: 20),
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
                            color: Color(0xFF1A237E),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Step 3',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                              letterSpacing: 2,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            'Terms & Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A237E),
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
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Terms Box
                            Container(
                              height: 250,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const SingleChildScrollView(
                                child: Text(
                                  """SHOP OWNER TERMS & AGREEMENT

Last updated: 16 December 2025

By registering as a Shop Owner on this Platform (the "Platform"), you agree to the following Terms & Agreement. If you do not agree, you must not use the Platform.

1. Role of the Platform

1.1 The Platform is a technology intermediary that connects customers, shop owners, and drivers.

1.2 The Platform does not own, manufacture, prepare, or sell any products listed by Shop Owners.

2. Eligibility & Registration

2.1 The Shop Owner confirms that they are legally permitted to operate a business in the Sultanate of Oman.

2.2 Valid business documentation (including Commercial Registration or relevant license) must be provided upon request.

2.3 The Shop Owner is responsible for maintaining accurate and up-to-date account information.

3. Products & Compliance

3.1 The Shop Owner is fully responsible for:

Product quality and safety

Accurate descriptions and pricing

Compliance with health, safety, and consumer protection laws

3.2 The Platform reserves the right to remove products or suspend listings that violate laws or Platform policies.

4. Orders & Fulfillment

4.1 The Shop Owner agrees to prepare and fulfill confirmed orders in a timely and professional manner.

4.2 Repeated delays, cancellations, or incorrect orders may result in penalties, reduced visibility, or account suspension.

4.3 The Platform is not responsible for losses resulting from the Shop Owner's failure to fulfill orders correctly.

5. Payments, Fees & Taxes

5.1 The Platform may charge service or commission fees, which will be communicated separately.

5.2 Payouts will be made according to the Platform's payout schedule and provided bank details.

5.3 The Shop Owner is solely responsible for all applicable taxes, VAT, and financial obligations.

6. Suspension & Termination

6.1 The Platform may suspend or terminate a Shop Owner account for violations of these Terms, applicable laws, or repeated customer complaints.

6.2 Outstanding payments may be withheld during investigations or dispute resolution.

7. Limitation of Liability

7.1 The Platform is not liable for indirect, incidental, or consequential damages arising from the Shop Owner's use of the Platform.

8. Governing Law

8.1 These Terms are governed by the laws of the Sultanate of Oman.

9. Acceptance

By using the Platform, the Shop Owner confirms acceptance of these Terms & Agreement.""",
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
                                  activeColor:Color(0xFF1A237E),
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
                                  backgroundColor: Color(0xFF1A237E),
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
      // Use the DatabaseService to handle both Auth and Firestore
      String? error = await dbService.registerShopOwner(widget.data);

      if (!mounted) return;
      
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shop Owner Registration Complete! Pending approval."),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Login
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}
