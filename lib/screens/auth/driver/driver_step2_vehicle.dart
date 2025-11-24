import 'package:flutter/material.dart';
import 'driver_registration_model.dart';
import 'driver_step3_license.dart';
import '../../widgets/step_tracker_bar.dart';
import '../../../../routes/app_routes.dart';

class DriverStep2Vehicle extends StatefulWidget {
  final DriverRegistrationData data;
  const DriverStep2Vehicle({super.key, required this.data});

  @override
  State<DriverStep2Vehicle> createState() => _DriverStep2VehicleState();
}

class _DriverStep2VehicleState extends State<DriverStep2Vehicle> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController vehicleTypeController;
  late TextEditingController plateNumberController;
  late TextEditingController licenseNumberController;

  @override
  void initState() {
    super.initState();
    vehicleTypeController = TextEditingController(text: widget.data.vehicleType);
    plateNumberController = TextEditingController(text: widget.data.plateNumber);
    licenseNumberController = TextEditingController(text: widget.data.licenseNumber);
  }

  @override
  void dispose() {
    vehicleTypeController.dispose();
    plateNumberController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }

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
                  // Top section
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
                              AppRoutes.driverRegisterStep1,
                              arguments: widget.data, // pass data back
                            );
                          },
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Step 2: Vehicle & License Info",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Next: Confirm Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form container
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            StepTrackerBar(currentStep: 2, totalSteps: 3),
                            const SizedBox(height: 24),
                            _buildField(vehicleTypeController, "Vehicle Type"),
                            const SizedBox(height: 16),
                            _buildField(plateNumberController, "Vehicle Plate Number"),
                            const SizedBox(height: 16),
                            _buildField(licenseNumberController, "Driver License Number"),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    widget.data.vehicleType = vehicleTypeController.text;
                                    widget.data.plateNumber = plateNumberController.text;
                                    widget.data.licenseNumber = licenseNumberController.text;

                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.driverRegisterStep3,
                                      arguments: widget.data,
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
                                  "Next",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? "Enter $label" : null,
    );
  }
}
