import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gmail SMTP Config
  static const String _senderEmail = 'dobi.app.otp@gmail.com';
  static const String _appPassword = 'ujvo qkbl nmgm mgyf';
  static const int _otpExpiryMinutes = 5;

  /// Generate a random 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to the provided email address
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      // Generate OTP
      final otp = generateOTP();

      // Store OTP in Firestore with expiration
      await _storeOTP(email, otp);

      // Send email via SMTP
      await _sendEmail(email, otp);

      return {
        'success': true,
        'message': 'OTP sent successfully to $email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
      };
    }
  }

  /// Store OTP in Firestore with expiration timestamp
  Future<void> _storeOTP(String email, String otp) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: _otpExpiryMinutes));

    // Delete any existing OTP for this email
    await deleteOTP(email);

    // Store new OTP
    await _firestore.collection('otp_codes').add({
      'email': email.trim().toLowerCase(),
      'otp': otp,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  /// Send OTP email via Gmail SMTP
  Future<void> _sendEmail(String recipientEmail, String otp) async {
    final smtpServer = gmail(_senderEmail, _appPassword);

    final message = Message()
      ..from = Address(_senderEmail, 'Dobbie App')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Dobbie Password Reset OTP'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #6A85B6; text-align: center;">Dobbie Password Reset</h2>
          <p>Hello,</p>
          <p>You have requested to reset your password. Please use the following OTP code:</p>
          <div style="background-color: #f4f4f4; padding: 20px; text-align: center; border-radius: 10px; margin: 20px 0;">
            <h1 style="color: #333; letter-spacing: 8px; font-size: 36px; margin: 0;">$otp</h1>
          </div>
          <p style="color: #666;">This code will expire in <strong>$_otpExpiryMinutes minutes</strong>.</p>
          <p style="color: #666;">If you didn't request this, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #999; font-size: 12px; text-align: center;">
            &copy; 2024 Dobbie App. All rights reserved.
          </p>
        </div>
      ''';

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      throw Exception('Failed to send email: ${e.message}');
    }
  }

  /// Verify the OTP entered by user
  Future<Map<String, dynamic>> verifyOTP(String email, String enteredOTP) async {
    try {
      final emailLower = email.trim().toLowerCase();

      // Query for matching OTP
      final querySnapshot = await _firestore
          .collection('otp_codes')
          .where('email', isEqualTo: emailLower)
          .where('otp', isEqualTo: enteredOTP)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid OTP. Please try again.',
        };
      }

      final doc = querySnapshot.docs.first;
      final expiresAt = (doc.data()['expiresAt'] as Timestamp).toDate();

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await deleteOTP(email);
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // OTP is valid - delete it
      await deleteOTP(email);

      return {
        'success': true,
        'message': 'OTP verified successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: ${e.toString()}',
      };
    }
  }

  /// Delete OTP records for an email
  Future<void> deleteOTP(String email) async {
    final emailLower = email.trim().toLowerCase();
    final querySnapshot = await _firestore
        .collection('otp_codes')
        .where('email', isEqualTo: emailLower)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}
