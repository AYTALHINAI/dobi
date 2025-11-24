import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import 'user_registration_model.dart';
import '../../widgets/step_tracker_bar.dart';

class UserRegisterStep2 extends StatefulWidget {
  final UserRegistrationData data;

  const UserRegisterStep2({super.key, required this.data});

  @override
  State<UserRegisterStep2> createState() => _UserRegisterStep2State();
}

class _UserRegisterStep2State extends State<UserRegisterStep2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addressController.text = widget.data.address;
    cityController.text = widget.data.city;
    postalCodeController.text = widget.data.postalCode;
  }

  @override
  void dispose() {
    addressController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
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
                  // Top section with back button & step info
                  Container(
                    height: screenHeight * 0.25,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 47),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 30),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Step 2: Location Information",
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
                            _buildTextField(addressController, "Address (Optional)"),
                            const SizedBox(height: 16),
                            _buildTextField(cityController, "City (Optional)"),
                            const SizedBox(height: 16),
                            _buildTextField(postalCodeController, "Postal Code (Optional)"),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: _btnStyle(Colors.grey.shade400),
                                    child: const Text("Back", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.data.address = addressController.text;
                                      widget.data.city = cityController.text;
                                      widget.data.postalCode = postalCodeController.text;
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.userRegisterStep3,
                                        arguments: widget.data,
                                      );
                                    },
                                    style: _btnStyle(Colors.black87),
                                    child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  ButtonStyle _btnStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
