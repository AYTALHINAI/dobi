import 'package:flutter/material.dart';
import 'driver_registration_model.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/step_tracker_bar.dart';
import 'package:lottie/lottie.dart';

class DriverStep2Vehicle extends StatefulWidget {
  final DriverRegistrationData data;
  const DriverStep2Vehicle({super.key, required this.data});

  @override
  State<DriverStep2Vehicle> createState() => _DriverStep2VehicleState();
}

class _DriverStep2VehicleState extends State<DriverStep2Vehicle> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController plateNumberController;
  late TextEditingController licenseNumberController;
  
  // Vehicle Type dropdown
  String? _selectedVehicleType;
  
  static const List<String> vehicleTypes = [
    'Sedan',
    'Hatchback',
    'SUV Models',
    'Pickup Models',
    'Van Models',
  ];

  @override
  void initState() {
    super.initState();
    plateNumberController = TextEditingController(text: widget.data.plateNumber);
    licenseNumberController = TextEditingController(text: widget.data.licenseNumber);
    
    // Initialize from existing data if available
    if (widget.data.vehicleType.isNotEmpty && 
        vehicleTypes.contains(widget.data.vehicleType)) {
      _selectedVehicleType = widget.data.vehicleType;
    }
  }

  @override
  void dispose() {
    plateNumberController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color primaryDeep = Color(0xFFffffff);
    const Color primaryLight = Color(0xFFffffff);

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
                                  FocusScope.of(context).unfocus();
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.driverRegisterStep1,
                                    arguments: widget.data,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Center(
                      child: Column(
                        children: [
                          Lottie.asset(
                            'assets/car.json',
                            height: 200,
                            repeat: true,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vehicle Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StepTrackerBar(
                                currentStep: 2, 
                                totalSteps: 3,
                                stepLabels: ['Personal', 'Vehicle', 'Terms'],
                              ),
                              const SizedBox(height: 24),

                              // Vehicle Type Dropdown
                              _buildDropdownField(
                                value: _selectedVehicleType,
                                hint: "Select Vehicle Type",
                                icon: Icons.directions_car,
                                items: vehicleTypes,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVehicleType = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please select a vehicle type";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                plateNumberController,
                                "Vehicle Plate Number",
                                Icons.pin_drop,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Vehicle Plate Number";
                                  if (!RegExp(r'^\d{1,5}[A-Z]+[A-Z]?$').hasMatch(v.trim())) {
                                    return "Invalid Oman plate format (e.g., 1234AB)";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              _infoBox("Format: 1234AB (Max 5 digits, then letters)"),
                              
                              const SizedBox(height: 16),

                              _buildTextField(
                                licenseNumberController,
                                "Driver License Number",
                                Icons.credit_card,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter License Number";
                                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v.trim())) {
                                    return "Invalid license number format";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 35),

                              // NEXT BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate() && _selectedVehicleType != null) {
                                      widget.data.vehicleType = _selectedVehicleType!;
                                      widget.data.plateNumber = plateNumberController.text.trim();
                                      widget.data.licenseNumber = licenseNumberController.text.trim();

                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.driverRegisterStep3,
                                        arguments: widget.data,
                                      );
                                    } else if (_selectedVehicleType == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please select a vehicle type"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: primaryDeep.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'NEXT STEP',
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

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    const primaryDeep = Color(0xFF1A237E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF5C6BC0)),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryDeep, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        hint: Text(
          hint,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.grey.shade600,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    const primaryDeep = Color(0xFF1A237E);

    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF5C6BC0)),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
          borderSide: const BorderSide(color: primaryDeep, width: 1.5),
        ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
      ),
    );
  }
}

