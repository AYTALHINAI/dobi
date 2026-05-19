import 'package:flutter_test/flutter_test.dart';
import 'package:dobi/screens/auth/driver/driver_step2_vehicle.dart';

void main() {
  group('DriverVehicleValidators', () {
    // --- Vehicle Plate Number Validation Tests ---
    group('validatePlateNumber', () {
      test('returns error if empty', () {
        expect(DriverVehicleValidators.validatePlateNumber(''), 'Enter Vehicle Plate Number');
        expect(DriverVehicleValidators.validatePlateNumber(null), 'Enter Vehicle Plate Number');
      });

      test('returns error if plate is invalid format', () {
        expect(DriverVehicleValidators.validatePlateNumber('ABCD'), 'Invalid Oman plate format (e.g., 1234AB)');
        expect(DriverVehicleValidators.validatePlateNumber('123456AB'), 'Invalid Oman plate format (e.g., 1234AB)');
      });

      test('returns null if plate is valid format', () {
        expect(DriverVehicleValidators.validatePlateNumber('1234AB'), null);
        expect(DriverVehicleValidators.validatePlateNumber('999A'), null);
      });
    });

    // --- Driver License Number Validation Tests ---
    group('validateLicenseNumber', () {
      test('returns error if empty', () {
        expect(DriverVehicleValidators.validateLicenseNumber(''), 'Enter License Number');
        expect(DriverVehicleValidators.validateLicenseNumber(null), 'Enter License Number');
      });

      test('returns error if license contains invalid characters', () {
        expect(DriverVehicleValidators.validateLicenseNumber('LIC-1234'), 'Invalid license number format');
      });

      test('returns null if license format is valid', () {
        expect(DriverVehicleValidators.validateLicenseNumber('12345678'), null);
        expect(DriverVehicleValidators.validateLicenseNumber('OMAN999'), null);
      });
    });
  });
}
