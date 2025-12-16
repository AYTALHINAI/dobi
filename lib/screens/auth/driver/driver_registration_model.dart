class DriverRegistrationData {
  // Step 1 – Basic Info
  String role = "driver";
  String fullName = "";
  String phone = "";
  String email = "";
  String password = "";

  // Step 2 – Vehicle Info
  String vehicleType = "";
  String plateNumber = "";

  // Step 3 – License Info
  String licenseNumber = "";

  // Terms Acceptance
  bool termsAccepted = false;

  DriverRegistrationData();

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'licenseNumber': licenseNumber,
      'termsAccepted': termsAccepted,
    };
  }

  bool isValid() {
    // Basic validation
    if (fullName.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return false;
    if (password.length < 6) return false;
    if (vehicleType.isEmpty || plateNumber.isEmpty || licenseNumber.isEmpty) return false;
    if (!termsAccepted) return false;
    return true;
  }
}

