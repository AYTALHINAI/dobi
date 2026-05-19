import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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

  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        bool isAdmin = userDoc.get('isAdmin') ?? false;
        String role = userDoc.get('role') ?? "user";
        return isAdmin ? "admin" : role;
      }

      DocumentSnapshot driverDoc = await _firestore.collection('drivers').doc(uid).get();
      if (driverDoc.exists) {
        return "driver";
      }

      DocumentSnapshot shopOwnerDoc = await _firestore.collection('shopOwners').doc(uid).get();
      if (shopOwnerDoc.exists) {
        return "shopOwner";
      }
    } catch (_) {}
    return "unknown";
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

  /// Live count of all registered users.
  Stream<int> watchTotalUsers() => _firestore
      .collection('users')
      .snapshots()
      .map((s) => s.docs.length);

  /// Live count of approved drivers.
  Stream<int> watchTotalDrivers() => _firestore
      .collection('drivers')
      .where('applicationStatus', isEqualTo: 'approved')
      .snapshots()
      .map((s) => s.docs.length);

  /// Live count of approved shop owners.
  Stream<int> watchTotalShopOwners() => _firestore
      .collection('shopOwners')
      .where('applicationStatus', isEqualTo: 'approved')
      .snapshots()
      .map((s) => s.docs.length);

  /// Live count of all orders.
  Stream<int> watchTotalOrders() => _firestore
      .collection('orders')
      .snapshots()
      .map((s) => s.docs.length);

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
      _firestore.collection('shopOwners').doc(uid).update({'shopImageUrl': url, 'profileImageUrl': url});

  /// Save (or overwrite) the shop owner profile image URL.
  Future<void> updateShopOwnerProfileImage(String uid, String url) =>
      _firestore.collection('shopOwners').doc(uid).update({'profileImageUrl': url, 'shopImageUrl': url});

  /// Remove the shop cover photo (sets both shared image fields to null).
  Future<void> deleteShopPhoto(String uid) =>
      _firestore.collection('shopOwners').doc(uid).update({
        'shopImageUrl': FieldValue.delete(),
        'profileImageUrl': FieldValue.delete(),
      });

  /// Save the shop owner's map location.
  Future<void> updateShopLocation(
          String uid, double latitude, double longitude) =>
      _firestore.collection('shopOwners').doc(uid).update({
        'latitude': latitude,
        'longitude': longitude,
      });

  /// Update editable shop info fields (shopPhone, shopAddress).
  Future<void> updateShopOwnerInfo(
          String uid, Map<String, dynamic> fields) =>
      _firestore
          .collection('shopOwners')
          .doc(uid)
          .update(fields);

  /// Fetch all approved shop owners as a list of data maps.
  Future<List<Map<String, dynamic>>> getApprovedShopOwnersList() async {
    final snap = await _firestore
        .collection('shopOwners')
        .where('applicationStatus', isEqualTo: 'approved')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  /// Fetch all approved drivers as a list of data maps.
  Future<List<Map<String, dynamic>>> getApprovedDriversList() async {
    final snap = await _firestore
        .collection('drivers')
        .where('applicationStatus', isEqualTo: 'approved')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  /// Fetch all customers as a list of data maps.
  Future<List<Map<String, dynamic>>> getCustomersList() async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  /// Permanently delete a shop owner document.
  Future<void> deleteShopOwner(String uid) =>
      _firestore.collection('shopOwners').doc(uid).delete();

  /// Permanently delete a driver document.
  Future<void> deleteDriver(String uid) =>
      _firestore.collection('drivers').doc(uid).delete();

  /// Permanently delete a customer document.
  Future<void> deleteCustomer(String uid) =>
      _firestore.collection('users').doc(uid).delete();

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

  /// Remove the user profile image URL from Firestore.
  Future<void> deleteUserProfileImage(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .update({'profileImageUrl': FieldValue.delete()});

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
  // ─────────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN  (Customer / User role only)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Signs in with Google and returns:
  ///   `"new"`      – first time; a minimal Firestore user doc is created.
  ///   `"existing"` – returning user; Firestore doc already present.
  /// Throws a human-readable string on failure or cancellation.
  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Always sign out first to clear the cached account so the
      // account picker is shown every time (prevents silent re-login).
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign-in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User firebaseUser = userCredential.user!;

      // Check whether the user doc already exists in Firestore
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // New user — create a minimal document; profile will be completed next
        await docRef.set({
          'uid': firebaseUser.uid,
          'role': 'user',
          'isAdmin': false,
          'email': firebaseUser.email ?? '',
          'fullName': firebaseUser.displayName ?? '',
          'displayName': firebaseUser.displayName ?? '',
          'profileImageUrl': firebaseUser.photoURL ?? '',
          'isNewGoogleUser': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return 'new';
      }

      return 'existing';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'This email is already registered with a different sign-in method.';
        case 'network-request-failed':
          throw 'Network error. Please check your connection.';
        default:
          throw 'Google sign-in failed. Please try again.';
      }
    } catch (e) {
      throw e.toString();
    }
  }

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

  // ─────────────────────────────────────────────────────────────────────────────
  // ORDERS – reads & writes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Live stream of the current user's orders (sorted client-side to avoid
  /// requiring a composite Firestore index).
  Stream<QuerySnapshot> getUserOrdersStream(String uid) => _firestore
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .snapshots();

  /// Live stream of a single order document (for the tracking page).
  Stream<DocumentSnapshot> getOrderStream(String orderId) =>
      _firestore.collection('orders').doc(orderId).snapshots();

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    await _firestore.collection('orders').add(orderData);
  }

  Future<void> updateOrderPaymentStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({'paymentStatus': status});
  }

  Stream<QuerySnapshot> getApprovedShops() {
    return _firestore
        .collection('shopOwners')
        .where('applicationStatus', isEqualTo: 'approved')
        .snapshots();
  }

  /// Live stream of a shop's orders (sorted client-side to avoid
  /// requiring a composite Firestore index).
  Stream<QuerySnapshot> getShopOrdersStream(String shopId) {
    return _firestore
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  /// Available orders for the driver Available tab:
  /// • pending orders (no pickupDriverId) → driver picks up from customer
  /// • ready orders (no driverId) → driver delivers to customer
  Stream<QuerySnapshot> getDriverPickupAndDeliveryOrders() {
    // Firestore doesn't support OR queries across fields in a single stream,
    // so we merge two streams client-side via StreamBuilder on the page.
    // Instead, fetch all unassigned orders with status in [pending, ready].
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['order_placed', 'ready_for_pickup'])
        .snapshots();
  }

  /// Legacy alias kept for compatibility.
  Stream<QuerySnapshot> getDriverAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'ready_for_pickup')
        .where('driverId', isNull: true)
        .snapshots();
  }

  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'driverId': driverId,
      'status': 'driver_assigned',
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({'status': newStatus});
    await notifyOrderStatus(orderId, newStatus);
  }

  Future<void> notifyOrderStatus(String orderId, String newStatus) async {
    try {
      // 1. Fetch order document
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['userId'] as String?;
      if (userId == null || userId.isEmpty) return;
      final orderRef = orderData['orderRef'] as String? ?? '—';
      final shopName = orderData['shopName'] as String? ?? 'Laundry Shop';

      // 2. Fetch customer settings
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data() as Map<String, dynamic>;
      final recipientEmail = userData['email'] as String?;
      final emailEnabled = userData['emailNotificationsEnabled'] as bool? ?? true;
      final inAppEnabled = userData['inAppNotificationsEnabled'] as bool? ?? true;

      // Map newStatus to user-friendly titles and messages
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'order_placed':
          title = 'Order Placed Successfully';
          body = 'Your order $orderRef has been placed successfully at $shopName.';
          break;
        case 'driver_assigned':
          title = 'Driver Assigned';
          body = 'A driver has been assigned to collect your laundry for order $orderRef.';
          break;
        case 'heading_to_shop':
          title = 'Laundry Collected';
          body = 'The driver has collected your laundry and is heading to $shopName.';
          break;
        case 'at_shop_processing':
          title = 'Cleaning Started';
          body = 'Your laundry is now being cleaned at $shopName.';
          break;
        case 'ready_for_pickup':
          title = 'Laundry Ready';
          body = 'Your laundry is clean and ready for pickup at $shopName.';
          break;
        case 'driver_heading_to_shop_delivery':
          title = 'Delivery Driver Assigned';
          body = 'A driver is heading to $shopName to collect your clean laundry.';
          break;
        case 'heading_to_customer':
          title = 'Out for Delivery';
          body = 'The driver is on the way to deliver your clean laundry!';
          break;
        case 'completed':
          title = 'Laundry Delivered';
          body = 'Your laundry has been delivered. Thank you for choosing Dobbie!';
          break;
        default:
          title = 'Order Status Updated';
          body = 'Your order $orderRef status is now: $newStatus.';
      }

      // 3. Store In-App Notification if enabled
      if (inAppEnabled) {
        await _firestore.collection('users').doc(userId).collection('notifications').add({
          'title': title,
          'body': body,
          'status': newStatus,
          'orderId': orderId,
          'orderRef': orderRef,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // 4. Send Email Notification if enabled and email is present
      if (emailEnabled && recipientEmail != null && recipientEmail.isNotEmpty) {
        await _sendNotificationEmail(recipientEmail, title, body, orderRef, newStatus);
      }
    } catch (e) {
      print('Error in notifyOrderStatus: $e');
    }
  }

  Future<void> _sendNotificationEmail(
    String recipientEmail,
    String title,
    String body,
    String orderRef,
    String status,
  ) async {
    // Reusing the Gmail SMTP credentials from OtpService
    const String senderEmail = 'dobi.app.otp@gmail.com';
    const String appPassword = 'ujvo qkbl nmgm mgyf';

    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = const Address(senderEmail, 'Dobbie App')
      ..recipients.add(recipientEmail)
      ..subject = 'Dobbie Notification: $title'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #ffffff;">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #5C6BC0; margin: 0; font-size: 24px; font-weight: 700;">Dobbie Updates</h2>
            <p style="color: #666; margin: 4px 0 0 0; font-size: 14px;">Real-time laundry tracking</p>
          </div>
          
          <div style="background-color: #F5F6FA; border-left: 4px solid #5C6BC0; padding: 16px; border-radius: 4px; margin-bottom: 24px;">
            <h3 style="color: #333333; margin: 0 0 8px 0; font-size: 16px;">$title</h3>
            <p style="color: #555555; margin: 0; font-size: 14px; line-height: 1.5;">$body</p>
          </div>

          <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
            <tr>
              <td style="padding: 8px 0; color: #777777; font-size: 13px; width: 120px;">Order Ref:</td>
              <td style="padding: 8px 0; color: #333333; font-size: 14px; font-weight: bold;">$orderRef</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #777777; font-size: 13px;">Status:</td>
              <td style="padding: 8px 0; color: #333333; font-size: 14px;">
                <span style="background-color: #E8EAF6; color: #3F51B5; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;">$status</span>
              </td>
            </tr>
          </table>

          <div style="text-align: center; border-top: 1px solid #eeeeee; padding-top: 20px;">
            <p style="color: #999999; font-size: 11px; margin: 0;">
              You received this because you enabled notifications in your account settings.
            </p>
            <p style="color: #999999; font-size: 11px; margin: 4px 0 0 0;">
              &copy; 2026 Dobbie App. All rights reserved.
            </p>
          </div>
        </div>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print('SMTP Email Sending failed: $e');
    }
  }

  Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markNotificationsAsRead(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Active orders for a driver: picked (heading to shop) or out_for_delivery (heading to customer).
  Stream<QuerySnapshot> getDriverActiveOrders(String driverId) {
    // Both pickup leg (pickupDriverId) and delivery leg (driverId) use the same driver.
    // We fetch by driverId for simplicity; pickup orders use pickupDriverId.
    // Use a broader query and filter client-side.
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['driver_assigned', 'driver_heading_to_shop_delivery', 'heading_to_customer'])
        .snapshots()
        .map((snap) {
      // Keep only orders belonging to this driver (either leg)
      final filtered = snap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['pickupDriverId'] == driverId ||
            data['driverId'] == driverId;
      }).toList();
      // Return a fake QuerySnapshot — we use the raw list directly in the widget.
      return snap;
    });
  }

  /// History orders for a driver (includes completed delivery legs and completed pickup legs).
  Stream<QuerySnapshot> getDriverOrderHistory(String driverId) {
    return _firestore
        .collection('orders')
        .where(Filter.or(
          Filter('driverId', isEqualTo: driverId),
          Filter('pickupDriverId', isEqualTo: driverId),
        ))
        .snapshots();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FEEDBACK
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> submitFeedback(Map<String, dynamic> feedbackData) async {
    final batch = _firestore.batch();
    
    // Add to feedback collection
    final feedbackRef = _firestore.collection('feedback').doc();
    batch.set(feedbackRef, feedbackData);

    // Update order document to mark feedback given
    final orderRef = _firestore.collection('orders').doc(feedbackData['orderId']);
    batch.update(orderRef, {'feedbackGiven': true});

    await batch.commit();
  }

  Stream<QuerySnapshot> getShopFeedbacksStream(String shopId) {
    return _firestore
        .collection('feedback')
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  Future<void> replyToFeedback(String feedbackId, String replyText) async {
    await _firestore.collection('feedback').doc(feedbackId).update({
      'shopReply': replyText,
      'shopReplyAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot?> getFeedbackForOrder(String orderId) async {
    final querySnapshot = await _firestore
        .collection('feedback')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  Stream<double> getShopAverageRating(String shopId) {
    return _firestore
        .collection('feedback')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      }
      return total / snapshot.docs.length;
    });
  }

  Future<double> getShopAverageRatingFuture(String shopId) async {
    final querySnapshot = await _firestore
        .collection('feedback')
        .where('shopId', isEqualTo: shopId)
        .get();
    
    if (querySnapshot.docs.isEmpty) return 0.0;
    double total = 0;
    for (var doc in querySnapshot.docs) {
      total += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }
    return total / querySnapshot.docs.length;
  }
}
