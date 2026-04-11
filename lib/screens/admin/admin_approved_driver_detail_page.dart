import 'package:flutter/material.dart';
import 'admin_detail_widgets.dart';

/// Read-only view of an approved driver.
class AdminApprovedDriverDetailPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const AdminApprovedDriverDetailPage({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text(
          'Driver Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminDetailHeroCard(
            initial:
                ((driverData['fullName'] as String?) ?? 'D')[0].toUpperCase(),
            title: driverData['fullName'] ?? 'No Name',
            subtitle: driverData['email'] ?? '',
            accentColor: Colors.orange,
            icon: Icons.delivery_dining_rounded,
          ),
          const SizedBox(height: 20),

          AdminDetailSectionHeader(
              title: 'Personal Information', icon: Icons.person),
          AdminDetailInfoRow(
              label: 'Full Name', value: driverData['fullName']),
          AdminDetailInfoRow(label: 'Email', value: driverData['email']),
          AdminDetailInfoRow(label: 'Phone', value: driverData['phone']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Vehicle Information',
              icon: Icons.directions_car_outlined),
          AdminDetailInfoRow(
              label: 'Vehicle Type', value: driverData['vehicleType']),
          AdminDetailInfoRow(
              label: 'Plate Number', value: driverData['plateNumber']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'License', icon: Icons.badge_outlined),
          AdminDetailInfoRow(
              label: 'License No.', value: driverData['licenseNumber']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Status', icon: Icons.verified_outlined),
          AdminDetailStatusChip(status: driverData['applicationStatus']),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
