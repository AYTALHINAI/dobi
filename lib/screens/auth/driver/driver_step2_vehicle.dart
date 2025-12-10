import 'package:flutter/material.dart';
import 'driver_registration_model.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/step_tracker_bar.dart';

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
    return Scaffold(
      body: Stack(
        children: [
          // Top grey background
          Container(color: Colors.grey.shade300.withOpacity(0.9)),

          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Top section
                Container(
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
                            arguments: widget.data,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
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

                // White form container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StepTrackerBar(currentStep: 2, totalSteps: 3),
                        const SizedBox(height: 24),

                        // Vehicle Type
                        _buildField(
                          vehicleTypeController,
                          "Vehicle Type",
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Enter Vehicle Type";
                            if (v.trim().length < 4) return "Vehicle Type must be at least 4 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Plate Number
                        _buildField(
                          plateNumberController,
                          "Vehicle Plate Number",
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Enter Vehicle Plate Number";

                            // Oman plate number regex: up to 5 digits, 1+ letters, optional single letter
                            if (!RegExp(r'^\d{1,5}[A-Z]+[A-Z]?$').hasMatch(v.trim())) {
                              return "Invalid Oman plate number format";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // Plate Number Info Box
                        _infoBox(
                          "Format: 1(234) A(B)\n- Up to 5 digits at the start\n- 1 or more letters in the middle\n- Optional single letter at the end\n- Uppercase letters only",
                        ),
                        const SizedBox(height: 16),

                        // Driver License Number
                        _buildField(
                          licenseNumberController,
                          "Driver License Number",
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Enter Driver License Number";
                            if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v.trim())) {
                              return "Invalid license number format";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // License Info Box
                        _infoBox(
                          "Format: e.g., D1234567\nOnly uppercase letters and numbers allowed",
                        ),
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
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label, {
        String? Function(String?)? validator,
      }) {
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
      validator: validator ?? (v) => v == null || v.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
