import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/auth/user/user_register_step1.dart';

void main() {
  group('RegisterValidators', () {
    // --- Full Name Validation Tests ---
    group('validateFullName', () {
      test('returns error if empty', () {
        expect(RegisterValidators.validateFullName(''), 'Enter Full Name');
        expect(RegisterValidators.validateFullName(null), 'Enter Full Name');
      });

      test('returns error if too short', () {
        expect(RegisterValidators.validateFullName('Ab'), 'Name must be at least 3 characters');
      });

      test('returns error if contains non-letters', () {
        expect(RegisterValidators.validateFullName('John123'), 'Name can contain letters only');
      });

      test('returns null if valid name', () {
        expect(RegisterValidators.validateFullName('John Doe'), null);
      });
    });

    // --- Phone Number Validation Tests ---
    group('validatePhone', () {
      test('returns error if empty', () {
        expect(RegisterValidators.validatePhone(''), 'Enter Phone Number');
        expect(RegisterValidators.validatePhone(null), 'Enter Phone Number');
      });

      test('returns error if contains non-digits', () {
        expect(RegisterValidators.validatePhone('987654a'), 'Phone must contain numbers only');
      });

      test('returns error if length is not 8 digits', () {
        expect(RegisterValidators.validatePhone('987654'), 'Phone number must be exactly 8 digits');
        expect(RegisterValidators.validatePhone('987654321'), 'Phone number must be exactly 8 digits');
      });

      test('returns error if prefix is not 7 or 9', () {
        expect(RegisterValidators.validatePhone('65432109'), 'Phone number must start with 7 or 9');
      });

      test('returns null if valid phone number', () {
        expect(RegisterValidators.validatePhone('91234567'), null);
        expect(RegisterValidators.validatePhone('71234567'), null);
      });
    });

    // --- Email Validation Tests ---
    group('validateEmail', () {
      test('returns error if empty', () {
        expect(RegisterValidators.validateEmail(''), 'Enter Email');
        expect(RegisterValidators.validateEmail(null), 'Enter Email');
      });

      test('returns error if invalid email format', () {
        expect(RegisterValidators.validateEmail('invalid'), 'Enter a valid email');
      });

      test('returns null if valid email', () {
        expect(RegisterValidators.validateEmail('user@test.com'), null);
      });
    });

    // --- Password Validation Tests ---
    group('validatePassword', () {
      test('returns error if empty', () {
        expect(RegisterValidators.validatePassword(''), 'Enter Password');
        expect(RegisterValidators.validatePassword(null), 'Enter Password');
      });

      test('returns error if less than 6 chars', () {
        expect(RegisterValidators.validatePassword('Pas1'), 'Min 6 characters');
      });

      test('returns error if no uppercase letter', () {
        expect(RegisterValidators.validatePassword('pass123'), 'Must contain an uppercase letter');
      });

      test('returns error if no lowercase letter', () {
        expect(RegisterValidators.validatePassword('PASS123'), 'Must contain a lowercase letter');
      });

      test('returns error if no number', () {
        expect(RegisterValidators.validatePassword('Password'), 'Must contain a number');
      });

      test('returns null if strong password', () {
        expect(RegisterValidators.validatePassword('Secure123'), null);
      });
    });

    // --- Confirm Password Validation Tests ---
    group('validateConfirmPassword', () {
      test('returns error if empty', () {
        expect(RegisterValidators.validateConfirmPassword('', 'Secure123'), 'Enter Confirm Password');
        expect(RegisterValidators.validateConfirmPassword(null, 'Secure123'), 'Enter Confirm Password');
      });

      test('returns error if passwords do not match', () {
        expect(RegisterValidators.validateConfirmPassword('Mismatch123', 'Secure123'), 'Passwords do not match');
      });

      test('returns null if passwords match', () {
        expect(RegisterValidators.validateConfirmPassword('Secure123', 'Secure123'), null);
      });
    });
  });
}
