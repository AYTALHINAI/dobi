class ShopOwnerRegistrationData {
  // Step 1 - Personal Info
  String? fullName;
  String? phone;
  String? email;
  String? password;
  String? confirmPassword;

  // Step 2 - Shop Info
  String? shopName;
  String? shopAddress;
  String? shopPhone;
  String? shopEmail;

  // Step 3 - Terms & Agreement
  bool agreedToTerms = false;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'shopPhone': shopPhone,
      'shopEmail': shopEmail,
      'agreedToTerms': agreedToTerms,
    };
  }

  bool isValidStep1() {
    return fullName != null &&
        fullName!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty &&
        confirmPassword != null &&
        confirmPassword == password;
  }

  bool isValidStep2() {
    return shopName != null &&
        shopName!.isNotEmpty &&
        shopAddress != null &&
        shopAddress!.isNotEmpty;
  }

  bool isValidStep3() {
    return agreedToTerms;
  }
}
