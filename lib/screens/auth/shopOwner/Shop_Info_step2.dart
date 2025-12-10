import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/step_tracker_bar.dart';
import 'shop_owner_registration_model.dart'; // Corrected Import

class ShopOwnerStep2ShopInfo extends StatefulWidget {
  final ShopOwnerRegistrationData data;
  const ShopOwnerStep2ShopInfo({super.key, required this.data});

  @override
  State<ShopOwnerStep2ShopInfo> createState() => _ShopOwnerStep2ShopInfoState();
}

class _ShopOwnerStep2ShopInfoState extends State<ShopOwnerStep2ShopInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController shopNameController;
  late TextEditingController shopAddressController;

  @override
  void initState() {
    super.initState();
    shopNameController = TextEditingController(text: widget.data.shopName);
    shopAddressController = TextEditingController(text: widget.data.shopAddress);
  }

  @override
  void dispose() {
    shopNameController.dispose();
    shopAddressController.dispose();
    super.dispose();
  }

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
                                  FocusScope.of(context).unfocus();
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.shopRegisterStep1, // Updated Route Name
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
                            Icons.store_mall_directory_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Step 2',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            'Shop Information',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StepTrackerBar(
                                currentStep: 2, 
                                totalSteps: 3,
                                stepLabels: ['Personal', 'Shop Details', 'Terms'],
                              ),
                              const SizedBox(height: 24),

                              _buildTextField(
                                shopNameController,
                                "Shop Name",
                                Icons.store,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Shop Name";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                shopAddressController,
                                "Shop Address",
                                Icons.place,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Shop Address";
                                  
                                  // Must match "City, Area" and optionally ", PostalCode"
                                  final addressRegex = RegExp(r'^[^,]+,\s*[^,]+(,\s*\d+)?$');
                                  if (!addressRegex.hasMatch(v.trim())) {
                                    return "Enter address like: City, Area, 112 (postal code optional)";
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 8),
                              _infoBox('Enter main branch address initially\nCity, Area, Postal Code (postal code optional)'),

                              const SizedBox(height: 35),

                              // NEXT BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      widget.data.shopName = shopNameController.text.trim();
                                      widget.data.shopAddress = shopAddressController.text.trim();

                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.shopRegisterStep3, // Updated Route Name
                                        arguments: widget.data,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDeep,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: primaryDeep.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'NEXT STEPS',
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
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
