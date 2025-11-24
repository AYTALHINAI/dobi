class UserRegistrationData {
  String fullName;
  String phone;
  String email;
  String password;

  // Optional
  String address;
  String city;
  String postalCode;

  UserRegistrationData({
    this.fullName = "",
    this.phone = "",
    this.email = "",
    this.password = "",
    this.address = "",
    this.city = "",
    this.postalCode = "",
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
      "city": city,
      "postalCode": postalCode,
    };
  }
}
