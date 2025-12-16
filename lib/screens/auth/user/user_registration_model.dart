class UserRegistrationData {
  String fullName;
  String phone;
  String email;
  String password;

  // Optional
  String address;
  String governorate;
  String wilayat;

  UserRegistrationData({
    this.fullName = "",
    this.phone = "",
    this.email = "",
    this.password = "",
    this.address = "",
    this.governorate = "",
    this.wilayat = "",
  });

  bool isValid() {
    return fullName.isNotEmpty &&
        phone.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      "fullName": fullName,
      "phone": phone,
      "email": email,
      "address": address,
      "governorate": governorate,
      "wilayat": wilayat,
    };
  }
}
