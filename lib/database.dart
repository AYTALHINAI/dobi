import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/user/user_registration_model.dart';
import '../screens/auth/driver/driver_registration_model.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper → Remove null or empty fields
  Map<String, dynamic> cleanMap(Map<String, dynamic> data) {
    data.removeWhere((key, value) => value == null || value == "");
    return data;
  }

  /// Get all pending drivers
  Future<QuerySnapshot> getPendingDrivers() async {
    return _firestore
        .collection('drivers')
        .where('applicationStatus', isEqualTo: 'pending')
        .get();
  }

  /// Update driver status (approved/rejected)
  Future<void> updateDriverStatus(String uid, String status) async {
    Map<String, dynamic> updateData = {
      'applicationStatus': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('drivers').doc(uid).update(updateData);
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
  /// REGISTER DRIVER — with PENDING STATUS
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

      /// ------------------------------------------------
      /// 🔥 NEW FIELDS FOR DRIVER APPROVAL WORKFLOW
      /// ------------------------------------------------
      driverMap['applicationStatus'] = "pending";      // pending / approved / rejected
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
  /// LOGIN (user / driver / admin)
  /// ------------------------------------------------
  Future<String> loginUser(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      /// 🔹 First check USERS collection
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        bool isAdmin = userDoc.get('isAdmin') ?? false;
        String role = userDoc.get('role') ?? "user";
        return isAdmin ? "admin" : role;
      }

      /// 🔹 Then check DRIVERS collection
      DocumentSnapshot driverDoc =
      await _firestore.collection('drivers').doc(uid).get();

      if (driverDoc.exists) {
        String status = driverDoc.get('applicationStatus') ?? "pending";

        /// ------------------------------------------------
        /// 🔥 NEW DRIVER STATUS CHECK DURING LOGIN
        /// ------------------------------------------------
        if (status == "pending") {
          throw "Your application is under review. Please wait for approval.";
        }

        if (status == "rejected") {
          throw "Your application has been rejected.";
        }

        return "driver"; // APPROVED
      }

      throw "Profile not found. Please contact support.";

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
}
