import 'package:flutter/material.dart';
import 'driver_registration_model.dart';
import '../../widgets/step_tracker_bar.dart';
import '../../../routes/app_routes.dart';
import '../../../database.dart';

class DriverStep3License extends StatelessWidget {
  final DriverRegistrationData data;
  const DriverStep3License({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey.shade300.withOpacity(0.9)),
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                children: [
                  // ---------------------- HEADER ----------------------
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.driverRegisterStep2,
                              arguments: data,
                            );
                          },
                        ),
                        const Spacer(),
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                "Step 3: Confirm Information",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Submit to complete registration",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------------------- BODY ----------------------
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StepTrackerBar(currentStep: 3, totalSteps: 3),
                          const SizedBox(height: 24),
                          _reviewSection(),
                          const SizedBox(height: 30),

                          // ---------------------- SUBMIT BUTTON ----------------------
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final dbService = DatabaseService();

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );

                                // Register Driver
                                String? error = await dbService.registerDriver(data);

                                Navigator.pop(context); // close loading

                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $error")),
                                  );
                                } else {
                                  // Success: Application submitted with "pending" status
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Application submitted! Please wait for approval.",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Navigate back to login and clear history
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.login,
                                        (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Complete Registration",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
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

  // ---------------------- REVIEW SECTION ----------------------
  Widget _reviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Review your info:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _reviewRow("Full Name", data.fullName),
        _reviewRow("Phone", data.phone),
        _reviewRow("Email", data.email),
        _reviewRow("Vehicle Type", data.vehicleType),
        _reviewRow("Plate Number", data.plateNumber),
        _reviewRow("License Number", data.licenseNumber),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
