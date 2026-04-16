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
    addressController.text = widget.data.address;
    
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
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using simple size to avoid complex rebuilds
    final size = MediaQuery.of(context).size;

    // Premium Color Palette
    const Color primaryDeep = Color(0xFFFFFFFF); // Deep Indigo
    const Color primaryLight = Color(0xFFffffff); // Lighter Indigo
    
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
                                  Navigator.pop(context);
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
                            Icons.location_on_rounded,
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
                            'Location Info',
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
                                stepLabels: ['Personal', 'Address', 'Confirm'],
                              ),
                              const SizedBox(height: 24),

                              // Governorate Dropdown
                              _buildDropdownField(
                                value: _selectedGovernorate,
                                hint: "Select Governorate (Optional)",
                                icon: Icons.map_rounded,
                                items: governorates,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGovernorate = value;
                                    _selectedWilayat = null; // Reset wilayat when governorate changes
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Wilayat Dropdown (dynamic based on governorate)
                              _buildDropdownField(
                                value: _selectedWilayat,
                                hint: _selectedGovernorate == null 
                                    ? "Select Governorate First" 
                                    : "Select Wilayat (Optional)",
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
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                addressController, 
                                "House Number (Optional)", 
                                Icons.home_filled,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null; // Optional field
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                                    return "House number must contain only digits";
                                  }
                                  if (value.trim().length > 6) {
                                    return "House number cannot exceed 6 digits";
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
                                    widget.data.address = addressController.text.trim();
                                    widget.data.governorate = _selectedGovernorate ?? '';
                                    widget.data.wilayat = _selectedWilayat ?? '';
                                    
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.userRegisterStep3,
                                      arguments: widget.data,
                                    );
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
                                    'REVIEW & SUBMIT',
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
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF5C6BC0) : Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryDeep, width: 1.5),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const primaryDeep = Color(0xFF1A237E);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
