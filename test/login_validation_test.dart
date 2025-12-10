import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/auth/login_page.dart';

void main() {
  group('LoginValidators', () {
    // --- Email Validation Tests ---
    group('validateEmail', () {
      test('returns error if email is empty', () {
        expect(LoginValidators.validateEmail(''), 'Enter your email');
      });

      test('returns error if email is null', () {
        expect(LoginValidators.validateEmail(null), 'Enter your email');
      });

      test('returns error if email is invalid', () {
        expect(LoginValidators.validateEmail('invalid-email'), 'Enter a valid email');
      });

      test('returns null if email is valid', () {
        expect(LoginValidators.validateEmail('test@example.com'), null);
      });
    });

    // --- Password Validation Tests ---
    group('validatePassword', () {
      test('returns error if password is empty', () {
        expect(LoginValidators.validatePassword(''), 'Enter your password');
      });

      test('returns error if password is null', () {
        expect(LoginValidators.validatePassword(null), 'Enter your password');
      });

      test('returns null if password is valid', () {
        expect(LoginValidators.validatePassword('password123'), null);
      });
    });
  });
}
