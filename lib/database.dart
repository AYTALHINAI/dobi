import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/user/user_registration_model.dart';
import '../screens/auth/driver/driver_registration_model.dart';
import '../screens/auth/shopOwner/shop_owner_registration_model.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper → Remove null or empty fields
  Map<String, dynamic> cleanMap(Map<String, dynamic> data) {
    data.removeWhere((key, value) => value == null || value == "");
    return data;
  }

  /// ------------------------------------------------
  /// ADMIN- DRIVERS/SHOP_OWNERS OPERATIONS
  /// ------------------------------------------------

  Future<QuerySnapshot> getPendingDrivers() async {
    return _firestore
        .collection('drivers')
        .where('applicationStatus', isEqualTo: 'pending')
        .get();
  }

  Future<void> updateDriverStatus(String uid, String status) async {
    Map<String, dynamic> updateData = {
      'applicationStatus': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('drivers').doc(uid).update(updateData);
  }

  Future<QuerySnapshot> getPendingShopOwners() async {
    return _firestore
        .collection('shopOwners')
        .where('applicationStatus', isEqualTo: 'pending')
        .get();
  }

  Future<void> updateShopOwnerStatus(String uid, String status) async {
    Map<String, dynamic> updateData = {
      'applicationStatus': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('shopOwners').doc(uid).update(updateData);
  }



  /// ------------------------------------------------
  /// REGISTER USER
  /// ------------------------------------------------
  Future<String?> registerUser(UserRegistrationData data) async {
    try {
      if (!data.isValid()) return "Please complete all required fields.";

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: data.email,
        password: data.password,
      );

      String uid = cred.user!.uid;

      Map<String, dynamic> userMap = cleanMap(data.toMap());
      userMap['uid'] = uid;
      userMap['role'] = "user";
      userMap['isAdmin'] = false;
      userMap['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(uid).set(userMap);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  /// ------------------------------------------------
  /// REGISTER DRIVER
  /// ------------------------------------------------
  Future<String?> registerDriver(DriverRegistrationData data) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: data.email,
        password: data.password,
      );

      String uid = cred.user!.uid;

      Map<String, dynamic> driverMap = cleanMap(data.toMap());
      driverMap['uid'] = uid;
      driverMap['role'] = "driver";
      driverMap['isAdmin'] = false;
      driverMap['createdAt'] = FieldValue.serverTimestamp();

      driverMap['applicationStatus'] = "pending";
      driverMap['approvedAt'] = null;
      driverMap['rejectedAt'] = null;

      await _firestore.collection('drivers').doc(uid).set(driverMap);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  /// ------------------------------------------------
  /// REGISTER SHOP OWNER
  /// ------------------------------------------------
  Future<String?> registerShopOwner(ShopOwnerRegistrationData data) async {
    try {
      if (!data.isValidStep1() || !data.isValidStep2()) {
        return "Please complete all required fields.";
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: data.email!,
        password: data.password!,
      );

      String uid = cred.user!.uid;

      Map<String, dynamic> shopMap = cleanMap(data.toMap());
      shopMap['uid'] = uid;
      shopMap['role'] = "shopOwner";
      shopMap['isAdmin'] = false;
      shopMap['createdAt'] = FieldValue.serverTimestamp();

      shopMap['applicationStatus'] = "pending";
      shopMap['approvedAt'] = null;
      shopMap['rejectedAt'] = null;

      await _firestore.collection('shopOwners').doc(uid).set(shopMap);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  /// ------------------------------------------------
  /// FORGOT PASSWORD
  /// ------------------------------------------------
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return "Password reset link sent to your email.";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'network-request-failed':
          return "Network error. Please check your connection.";
        default:
          return "Password reset failed. Please try again.";
      }
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  /// ------------------------------------------------
  /// LOGIN (user / driver / shopOwner / admin)
  /// ------------------------------------------------
  Future<String> loginUser(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      /// Check USERS collection
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        bool isAdmin = userDoc.get('isAdmin') ?? false;
        String role = userDoc.get('role') ?? "user";
        return isAdmin ? "admin" : role;
      }

      /// Check DRIVERS collection
      DocumentSnapshot driverDoc = await _firestore.collection('drivers').doc(uid).get();
      if (driverDoc.exists) {
        String status = driverDoc.get('applicationStatus') ?? "pending";
        if (status == "pending") throw "Your application is under review. Please wait for approval.";
        if (status == "rejected") throw "Your application has been rejected.";
        return "driver";
      }

      /// Check SHOP OWNERS collection
      DocumentSnapshot shopOwnerDoc = await _firestore.collection('shopOwners').doc(uid).get();
      if (shopOwnerDoc.exists) {
        String status = shopOwnerDoc.get('applicationStatus') ?? "pending";
        if (status == "pending") throw "Your application is under review. Please wait for approval.";
        if (status == "rejected") throw "Your application has been rejected.";
        return "shopOwner";
      }

      throw "Login failed. Please try again.";

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw "Invalid email address.";
        case 'user-not-found':
        case 'wrong-password':
          throw "Email or password is incorrect.";
        case 'network-request-failed':
          throw "Network error. Please check your connection.";
        default:
          throw "Login failed. Please try again.";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// ------------------------------------------------
  /// CHECK IF EMAIL EXISTS IN FIREBASE
  /// ------------------------------------------------
  /// Checks if email exists in users, drivers, or shopOwners collections
  Future<bool> checkEmailExists(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Check in users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (usersQuery.docs.isNotEmpty) return true;

      // Check in drivers collection
      final driversQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (driversQuery.docs.isNotEmpty) return true;

      // Check in shopOwners collection
      final shopOwnersQuery = await _firestore
          .collection('shopOwners')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (shopOwnersQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      // If there's an error, we return false to be safe
      return false;
    }
  }

  /// ------------------------------------------------
  /// GET SHOP OWNER STATUS (for login handling)
  /// ------------------------------------------------
  /// Get shop owner status by email
  Future<String> getShopOwnerStatus(String email) async {
    try {
      var query = await _firestore
          .collection('shopOwners')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return "not_found";

      return query.docs.first.get('applicationStatus') ?? "pending";
    } catch (e) {
      return "unknown";
    }
  }

  /// ------------------------------------------------
  /// DASHBOARD COUNTS
  /// ------------------------------------------------

  /// Get total count of users
  Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total count of approved drivers
  Future<int> getTotalDrivers() async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('applicationStatus', isEqualTo: 'approved')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total count of approved shop owners
  Future<int> getTotalShopOwners() async {
    try {
      final snapshot = await _firestore
          .collection('shopOwners')
          .where('applicationStatus', isEqualTo: 'approved')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SHOP OWNER – reads & writes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch a single shop owner document.
  Future<DocumentSnapshot> getShopOwnerDoc(String uid) =>
      _firestore.collection('shopOwners').doc(uid).get();

  /// Live stream of all approved shop owners (for user-facing search).
  Stream<QuerySnapshot> getApprovedShopsStream() => _firestore
      .collection('shopOwners')
      .where('applicationStatus', isEqualTo: 'approved')
      .snapshots();

  /// Live stream of approved shops filtered by service category.
  /// [category] should be one of: 'cloth_cleaning', 'blanket_cleaning'
  Stream<QuerySnapshot> getShopsByCategoryStream(String category) => _firestore
      .collection('shopOwners')
      .where('applicationStatus', isEqualTo: 'approved')
      .where('categories', arrayContains: category)
      .snapshots();

  /// Live stream of a shop owner's services sub-collection.
  Stream<QuerySnapshot> getShopServicesStream(String uid) => _firestore
      .collection('shopOwners')
      .doc(uid)
      .collection('services')
      .orderBy('createdAt', descending: false)
      .snapshots();

  /// Save (or overwrite) the shop cover image URL on the shop owner doc.
  Future<void> updateShopCoverPhoto(String uid, String url) =>
      _firestore.collection('shopOwners').doc(uid).update({'shopImageUrl': url});

  /// Save (or overwrite) the shop owner profile image URL.
  Future<void> updateShopOwnerProfileImage(String uid, String url) =>
      _firestore.collection('shopOwners').doc(uid).update({'profileImageUrl': url});

  /// Save the shop owner's map location.
  Future<void> updateShopLocation(
          String uid, double latitude, double longitude) =>
      _firestore.collection('shopOwners').doc(uid).update({
        'latitude': latitude,
        'longitude': longitude,
      });

  /// Update an existing service document.
  Future<void> updateService(
    String uid,
    String serviceId,
    Map<String, dynamic> data,
  ) =>
      _firestore
          .collection('shopOwners')
          .doc(uid)
          .collection('services')
          .doc(serviceId)
          .update(data);

  /// Delete a service document and rebuild the shop's categories array.
  Future<void> deleteService(String uid, String serviceId) async {
    await _firestore
        .collection('shopOwners')
        .doc(uid)
        .collection('services')
        .doc(serviceId)
        .delete();
    // Rebuild categories from remaining services
    final remaining = await _firestore
        .collection('shopOwners')
        .doc(uid)
        .collection('services')
        .get();
    final categories = remaining.docs
        .map((d) => (d.data()['category'] as String?) ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    await _firestore
        .collection('shopOwners')
        .doc(uid)
        .update({'categories': categories});
  }

  /// Add a new service document and update the shop's categories array.
  Future<void> addService(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('shopOwners')
        .doc(uid)
        .collection('services')
        .add(data);
    // Denormalize category onto the shop doc for efficient customer queries
    final category = data['category'] as String?;
    if (category != null && category.isNotEmpty) {
      await _firestore.collection('shopOwners').doc(uid).update({
        'categories': FieldValue.arrayUnion([category]),
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // USER – reads & writes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch a single user document.
  Future<DocumentSnapshot> getUserDoc(String uid) =>
      _firestore.collection('users').doc(uid).get();

  /// Merge-save fields on a user document (non-destructive).
  Future<void> updateUserFields(String uid, Map<String, dynamic> data) =>
      _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));

  /// Save (or overwrite) the user profile image URL.
  Future<void> updateUserProfileImage(String uid, String url) =>
      updateUserFields(uid, {'profileImageUrl': url});

  /// Returns true if [phone] is already registered to a user OTHER than [currentUid].
  Future<bool> checkPhoneExistsForOtherUser(
      String phone, String currentUid) async {
    try {
      final q = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(2)
          .get();
      return q.docs.any((doc) => doc.id != currentUid);
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CART – reads & writes  (users/{uid}/cart/{cartItemId})
  // ─────────────────────────────────────────────────────────────────────────────

  /// Live stream of the current user's cart items.
  Stream<QuerySnapshot> getCartStream(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('cart')
      .orderBy('addedAt', descending: false)
      .snapshots();

  /// Add or overwrite a cart item. [cartItemId] is typically the serviceId
  /// so that re-adding the same service just updates the quantity.
  Future<void> addToCart(String uid, String cartItemId,
      Map<String, dynamic> item) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(cartItemId)
          .set(item);

  /// Update only the quantity field of an existing cart item.
  Future<void> updateCartItemQty(
      String uid, String cartItemId, int qty) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(cartItemId)
          .update({'quantity': qty});

  /// Remove a single item from the cart.
  Future<void> removeCartItem(String uid, String cartItemId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(cartItemId)
          .delete();

  /// Delete every item in the cart (batch for atomicity).
  Future<void> clearCart(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
