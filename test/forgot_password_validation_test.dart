import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/auth/forgot_password_page.dart';

void main() {
  group('ForgotPasswordPage Validators', () {
    group('validateEmail', () {
      test('returns error if email is empty', () {
        expect(ForgotPasswordValidators.validateEmail(''), 'Please enter your email.');
      });

      test('returns error if email is null', () {
        expect(ForgotPasswordValidators.validateEmail(null), 'Please enter your email.');
      });

      test('returns error if email is invalid', () {
        expect(ForgotPasswordValidators.validateEmail('invalid-email'), 'Please enter a valid email address.');
      });

      test('returns null if email is valid', () {
        expect(ForgotPasswordValidators.validateEmail('test@example.com'), null);
      });
    });
  });
}
