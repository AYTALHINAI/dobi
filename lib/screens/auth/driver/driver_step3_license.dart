import 'package:flutter/material.dart';
import 'driver_registration_model.dart';
import '../../widgets/step_tracker_bar.dart';
import '../../../routes/app_routes.dart';
import '../../../database.dart';

class DriverStep3License extends StatefulWidget {
  final DriverRegistrationData data;
  const DriverStep3License({super.key, required this.data});

  @override
  State<DriverStep3License> createState() => _DriverStep3LicenseState();
}

class _DriverStep3LicenseState extends State<DriverStep3License> {
  bool isAgreed = false;
  bool isSubmitting = false;

  static const String driverTermsText = '''DRIVER TERMS & AGREEMENT

Last updated: 16 December 2025

By registering as a Driver on this Platform (the "Platform"), you agree to the following Terms & Agreement. If you do not agree, you must not use the Platform.

1. Driver Status

1.1 Drivers operate as independent contractors, not employees, partners, or agents of the Platform.

1.2 The Platform does not guarantee minimum earnings, delivery volume, or working hours.

2. Eligibility & Documentation

2.1 Drivers must be legally eligible to work in Oman.

2.2 A valid driving license, vehicle registration, and insurance must be maintained at all times.

2.3 Drivers are responsible for the accuracy of all submitted documents.

3. Delivery Responsibilities

3.1 Drivers agree to complete deliveries safely, professionally, and within reasonable timeframes.

3.2 Orders must be handled with care and delivered according to instructions provided through the Platform.

3.3 Drivers are responsible for any traffic violations, fines, or accidents occurring during deliveries.

4. Payments & Expenses

4.1 Driver earnings are calculated based on delivery distance, time, or other criteria defined by the Platform.

4.2 Payments are made according to the Platform's payout schedule.

4.3 Drivers are responsible for all personal expenses, including fuel, maintenance, insurance, and mobile data.

5. Conduct & Performance

5.1 Drivers must maintain respectful behavior toward customers, shop owners, and Platform staff.

5.2 Fraud, misuse of the Platform, or repeated complaints may result in penalties or account suspension.

6. Suspension & Termination

6.1 The Platform may suspend or terminate Driver accounts for violations of these Terms or applicable laws.

6.2 Payments may be withheld during investigations related to fraud or misconduct.

7. Limitation of Liability

7.1 The Platform is not liable for injuries, losses, or damages incurred during deliveries.

8. Governing Law

8.1 These Terms are governed by the laws of the Sultanate of Oman.

9. Acceptance

By using the Platform, the Driver confirms acceptance of these Terms & Agreement.''';

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
                                    AppRoutes.driverRegisterStep2,
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
                              stepLabels: ['Personal', 'Vehicle', 'Terms'],
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
                              height: 250,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const SingleChildScrollView(
                                child: Text(
                                  driverTermsText,
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
                                        'COMPLETE REGISTRATION',
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
    
    // Set terms accepted
    widget.data.termsAccepted = true;
    
    final dbService = DatabaseService();

    String? error = await dbService.registerDriver(widget.data);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application submitted! Pending approval."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

