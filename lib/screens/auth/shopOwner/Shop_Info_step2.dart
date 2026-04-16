import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/step_tracker_bar.dart';
import 'shop_owner_registration_model.dart';

class ShopOwnerStep2ShopInfo extends StatefulWidget {
  final ShopOwnerRegistrationData data;
  const ShopOwnerStep2ShopInfo({super.key, required this.data});

  @override
  State<ShopOwnerStep2ShopInfo> createState() => _ShopOwnerStep2ShopInfoState();
}

class _ShopOwnerStep2ShopInfoState extends State<ShopOwnerStep2ShopInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController shopNameController;
  late TextEditingController shopPhoneController;
  late TextEditingController emailController;
  late TextEditingController shopAddressController;

  // Governorate and Wilayat data
  String? _selectedGovernorate;
  String? _selectedWilayat;

  // Map of Governorates to their Wilayats
  static const Map<String, List<String>> governorateWilayatMap = {
    'Muscat': ['Muttrah', 'Bawshar', 'Seeb', 'Al Amerat', 'Qurayyat'],
    'Dhofar': ['Salalah', 'Taqah', 'Mirbat', 'Thumrait', 'Sadah', 'Rakhyut', 'Dalkut', 'Muqshin'],
    'Musandam': ['Khasab', 'Bukha', 'Dibba Al Baya', 'Madha'],
    'Al Buraimi': ['Mahdah', 'Al Sinainah'],
    'Al Dakhiliyah': ['Nizwa', 'Bahla', 'Adam', 'Izki', 'Samail', 'Bidbid', 'Manah'],
    'Al Dhahirah': ['Ibri', 'Yanqul', 'Dhank'],
    'North Al Batinah': ['Sohar', 'Shinas', 'Liwa', 'Saham', 'Al Khaburah', 'Suwaiq'],
    'South Al Batinah': ['Rustaq', 'Nakhal', 'Wadi Al Maawil', 'Barka', 'Al Musannah'],
    'North Al Sharqiyah': ['Ibra', 'Al Mudhaibi', 'Bidiyah', 'Qabil', 'Wadi Bani Khalid', 'Dema Wa Thaieen'],
    'South Al Sharqiyah': ['Sur', 'Jalan Bani Bu Ali', 'Jalan Bani Bu Hassan', 'Al Kamil Wal Wafi', 'Masirah'],
    'Al Wusta': ['Haima', 'Duqm', 'Mahout', 'Al Jazer', 'Ibra (Al Wusta)'],
  };

  List<String> get governorates => governorateWilayatMap.keys.toList();

  List<String> get wilayats => _selectedGovernorate != null
      ? governorateWilayatMap[_selectedGovernorate]!
      : [];

  @override
  void initState() {
    super.initState();
    shopNameController = TextEditingController(text: widget.data.shopName);
    shopPhoneController = TextEditingController(text: widget.data.shopPhone);
    emailController = TextEditingController(text: widget.data.email);
    shopAddressController = TextEditingController(text: widget.data.shopAddress);
    
    // Initialize from existing data if available
    if (widget.data.governorate.isNotEmpty && 
        governorateWilayatMap.containsKey(widget.data.governorate)) {
      _selectedGovernorate = widget.data.governorate;
      if (widget.data.wilayat.isNotEmpty &&
          governorateWilayatMap[widget.data.governorate]!.contains(widget.data.wilayat)) {
        _selectedWilayat = widget.data.wilayat;
      }
    }
  }

  @override
  void dispose() {
    shopNameController.dispose();
    shopPhoneController.dispose();
    emailController.dispose();
    shopAddressController.dispose();
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
                                    AppRoutes.shopRegisterStep1,
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
                            color: Color(0xFF1A237E),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Step 2',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                              letterSpacing: 2,
                            ),
                          ),
                           SizedBox(height: 4),
                          Text(
                            'Shop Information',
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

                              // Shop Name
                              _buildTextField(
                                shopNameController,
                                "Shop Name",
                                Icons.store,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Shop Name";
                                  if (v.trim().length < 3) return "Shop name must be at least 3 characters";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Shop Phone Number
                              _buildTextField(
                                shopPhoneController,
                                "Shop Phone Number",
                                Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Shop Phone Number";
                                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) return "Phone must contain numbers only";
                                  if (v.length != 8) return "Phone number must be exactly 8 digits";
                                  if (!v.startsWith('9') && !v.startsWith('7')) {
                                    return "Phone number must start with 7 or 9";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email Field (for login)
                              _buildTextField(
                                emailController,
                                "Email (for login)",
                                Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Enter Email";
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Governorate Dropdown
                              _buildDropdownField(
                                value: _selectedGovernorate,
                                hint: "Select Governorate",
                                icon: Icons.map_rounded,
                                items: governorates,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGovernorate = value;
                                    _selectedWilayat = null; // Reset wilayat when governorate changes
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please select a governorate";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Wilayat Dropdown (dynamic based on governorate)
                              _buildDropdownField(
                                value: _selectedWilayat,
                                hint: _selectedGovernorate == null 
                                    ? "Select Governorate First" 
                                    : "Select Wilayat",
                                icon: Icons.location_city_rounded,
                                items: wilayats,
                                onChanged: _selectedGovernorate == null 
                                    ? null 
                                    : (value) {
                                        setState(() {
                                          _selectedWilayat = value;
                                        });
                                      },
                                enabled: _selectedGovernorate != null,
                                validator: (value) {
                                  if (_selectedGovernorate != null && (value == null || value.isEmpty)) {
                                    return "Please select a wilayat";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Shop/Building Number
                              _buildTextField(
                                shopAddressController,
                                "Shop/Building Number (Optional)",
                                Icons.home_work_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null; // Optional field
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                                    return "Building number must contain only digits";
                                  }
                                  if (v.trim().length > 6) {
                                    return "Building number cannot exceed 6 digits";
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
                                    if (_formKey.currentState!.validate()) {
                                      widget.data.shopName = shopNameController.text.trim();
                                      widget.data.shopPhone = shopPhoneController.text.trim();
                                      widget.data.email = emailController.text.trim();
                                      widget.data.shopAddress = shopAddressController.text.trim();
                                      widget.data.governorate = _selectedGovernorate ?? '';
                                      widget.data.wilayat = _selectedWilayat ?? '';

                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.shopRegisterStep3,
                                        arguments: widget.data,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1A237E),
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
    bool enabled = true,
  }) {
    const primaryDeep = Color(0xFF1A237E);

    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF5C6BC0) : Colors.grey),
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
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
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
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    const primaryDeep = Color(0xFF1A237E);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

