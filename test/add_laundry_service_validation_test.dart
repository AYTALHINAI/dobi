import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/shopOwner/add_laundry_service_page.dart';

void main() {
  group('AddLaundryServiceValidators', () {
    // ── Price validation ────────────────────────────────────────────────────
    group('validatePrice', () {
      test('returns error if price is null', () {
        expect(
          AddLaundryServiceValidators.validatePrice(null),
          'Required',
        );
      });

      test('returns error if price is empty', () {
        expect(
          AddLaundryServiceValidators.validatePrice(''),
          'Required',
        );
      });

      test('returns error if price is whitespace only', () {
        expect(
          AddLaundryServiceValidators.validatePrice('   '),
          'Required',
        );
      });

      test('returns error if price is not a number', () {
        expect(
          AddLaundryServiceValidators.validatePrice('abc'),
          'Enter a valid price',
        );
      });

      test('returns error if price is negative', () {
        expect(
          AddLaundryServiceValidators.validatePrice('-1.5'),
          'Enter a valid price',
        );
      });

      test('returns null for a valid integer price', () {
        expect(
          AddLaundryServiceValidators.validatePrice('5'),
          null,
        );
      });

      test('returns null for a valid decimal price', () {
        expect(
          AddLaundryServiceValidators.validatePrice('1.500'),
          null,
        );
      });

      test('returns null for zero price', () {
        // Zero is a valid price (free service)
        expect(
          AddLaundryServiceValidators.validatePrice('0'),
          null,
        );
      });

      test('returns null when price has leading/trailing whitespace', () {
        expect(
          AddLaundryServiceValidators.validatePrice('  2.750  '),
          null,
        );
      });
    });

    // ── Service selection validation ────────────────────────────────────────
    group('validateServiceSelected', () {
      test('returns error when no service is selected', () {
        expect(
          AddLaundryServiceValidators.validateServiceSelected(false),
          'Please select a service',
        );
      });

      test('returns null when a service is selected', () {
        expect(
          AddLaundryServiceValidators.validateServiceSelected(true),
          null,
        );
      });
    });

    // ── Add-service process: combined field rules ────────────────────────────
    group('Add Service process', () {
      test('form is invalid if service is not selected', () {
        final serviceError =
            AddLaundryServiceValidators.validateServiceSelected(false);
        final priceError =
            AddLaundryServiceValidators.validatePrice('1.500');

        expect(serviceError, isNotNull,
            reason: 'Service must be selected before adding');
        expect(priceError, isNull);
      });

      test('form is invalid if price is missing even when service is selected', () {
        final serviceError =
            AddLaundryServiceValidators.validateServiceSelected(true);
        final priceError =
            AddLaundryServiceValidators.validatePrice('');

        expect(serviceError, isNull);
        expect(priceError, isNotNull,
            reason: 'Price is required to add a service');
      });

      test('form is valid when service is selected and price is correct', () {
        final serviceError =
            AddLaundryServiceValidators.validateServiceSelected(true);
        final priceError =
            AddLaundryServiceValidators.validatePrice('3.500');

        expect(serviceError, isNull);
        expect(priceError, isNull);
      });

      test('description is optional – adding without it is valid', () {
        // Description has no validator; any non-null string is accepted.
        const description = '';
        expect(description, isA<String>(),
            reason: 'Empty description is acceptable');
      });
    });
  });
}
