class ShopOwnerRegistrationData {
  String ownerName = '';
  String phone = '';
  String? email = '';
  String? password = '';
  String shopName = '';
  String shopAddress = '';

  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'shopName': shopName,
      'shopAddress': shopAddress,
    };
  }

  bool isValidStep1() {
    return ownerName.isNotEmpty && phone.isNotEmpty && email != null && password != null;
  }

  bool isValidStep2() {
    return shopName.isNotEmpty && shopAddress.isNotEmpty;
  }
}
