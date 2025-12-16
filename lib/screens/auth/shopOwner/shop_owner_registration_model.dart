class ShopOwnerRegistrationData {
  // Step 1 - Owner Details
  String ownerName = '';
  String phone = '';
  String? password = '';

  // Step 2 - Shop Info
  String? email = '';
  String shopName = '';
  String shopPhone = '';
  String shopAddress = ''; // Building/Shop Number
  String governorate = '';
  String wilayat = '';

  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'shopName': shopName,
      'shopPhone': shopPhone,
      'shopAddress': shopAddress,
      'governorate': governorate,
      'wilayat': wilayat,
    };
  }

  bool isValidStep1() {
    return ownerName.isNotEmpty && phone.isNotEmpty && password != null && password!.isNotEmpty;
  }

  bool isValidStep2() {
    return shopName.isNotEmpty && 
           shopPhone.isNotEmpty && 
           email != null && 
           email!.isNotEmpty &&
           governorate.isNotEmpty && 
           wilayat.isNotEmpty;
  }
}

