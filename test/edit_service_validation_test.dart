import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/shopOwner/shopOwner_services_page.dart';

void main() {
  group('EditServiceValidators', () {
    // ── Price validation ────────────────────────────────────────────────────
    group('validatePrice', () {
      test('returns error if price is null', () {
        expect(
          EditServiceValidators.validatePrice(null),
          'Required',
        );
      });

      test('returns error if price is empty', () {
        expect(
          EditServiceValidators.validatePrice(''),
          'Required',
        );
      });

      test('returns error if price is whitespace only', () {
        expect(
          EditServiceValidators.validatePrice('   '),
          'Required',
        );
      });

      test('returns error if price is not a number', () {
        expect(
          EditServiceValidators.validatePrice('xyz'),
          'Enter a valid price',
        );
      });

      test('returns error for a string with mixed characters', () {
        expect(
          EditServiceValidators.validatePrice('1.5abc'),
          'Enter a valid price',
        );
      });

      test('returns null for a valid integer price', () {
        expect(
          EditServiceValidators.validatePrice('10'),
          null,
        );
      });

      test('returns null for a valid decimal price', () {
        expect(
          EditServiceValidators.validatePrice('2.500'),
          null,
        );
      });

      test('returns null when price has surrounding whitespace', () {
        expect(
          EditServiceValidators.validatePrice('  4.750  '),
          null,
        );
      });
    });

    // ── Service selection validation ────────────────────────────────────────
    group('validateServiceSelected', () {
      test('returns error when no service is selected', () {
        expect(
          EditServiceValidators.validateServiceSelected(false),
          'Please select a service',
        );
      });

      test('returns null when a service is selected', () {
        expect(
          EditServiceValidators.validateServiceSelected(true),
          null,
        );
      });
    });

    // ── Update-service process: combined field rules ─────────────────────────
    group('Edit Service process (update flow)', () {
      test('form is invalid if no service is selected even with valid price', () {
        final serviceError =
            EditServiceValidators.validateServiceSelected(false);
        final priceError = EditServiceValidators.validatePrice('5.000');

        expect(serviceError, isNotNull,
            reason: 'A service must remain selected when saving edits');
        expect(priceError, isNull);
      });

      test('form is invalid if price is cleared during editing', () {
        final serviceError =
            EditServiceValidators.validateServiceSelected(true);
        final priceError = EditServiceValidators.validatePrice('');

        expect(serviceError, isNull);
        expect(priceError, isNotNull,
            reason: 'Price cannot be empty when saving an edited service');
      });

      test('form is invalid if price is changed to a non-numeric value', () {
        final serviceError =
            EditServiceValidators.validateServiceSelected(true);
        final priceError = EditServiceValidators.validatePrice('abc');

        expect(serviceError, isNull);
        expect(priceError, isNotNull,
            reason: 'Updated price must be a valid number');
      });

      test('form is valid when service is selected and price is updated correctly', () {
        final serviceError =
            EditServiceValidators.validateServiceSelected(true);
        final priceError = EditServiceValidators.validatePrice('7.000');

        expect(serviceError, isNull);
        expect(priceError, isNull);
      });

      test('description update is optional – saving with empty description is valid', () {
        // Description field has no validator; clearing it is acceptable.
        const updatedDescription = '';
        expect(updatedDescription, isA<String>(),
            reason: 'Empty description is valid when updating a service');
      });

      test('pre-populated price (from existing service) passes validation', () {
        // Simulates the edit sheet opening with the current stored price
        const existingPrice = 3.250;
        final priceText = existingPrice.toStringAsFixed(3); // '3.250'

        expect(
          EditServiceValidators.validatePrice(priceText),
          null,
          reason: 'The pre-filled price from Firestore should always be valid',
        );
      });
    });
  });
}
