import 'package:flutter/material.dart';
import 'admin_detail_widgets.dart';

/// Read-only view of a customer.
class AdminCustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customerData;
  const AdminCustomerDetailPage({super.key, required this.customerData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text(
          'Customer Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminDetailHeroCard(
            initial:
                ((customerData['fullName'] as String?) ?? (customerData['displayName'] as String?) ?? 'C')[0].toUpperCase(),
            title: customerData['fullName'] ?? customerData['displayName'] ?? 'No Name',
            subtitle: customerData['email'] ?? '',
            accentColor: Colors.blue,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),

          AdminDetailSectionHeader(
              title: 'Personal Information', icon: Icons.person),
          AdminDetailInfoRow(
              label: 'Full Name', value: customerData['fullName'] ?? customerData['displayName']),
          AdminDetailInfoRow(label: 'Email', value: customerData['email']),
          AdminDetailInfoRow(label: 'Phone', value: customerData['phone']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Role & Status', icon: Icons.verified_outlined),
          AdminDetailInfoRow(
              label: 'Role', value: customerData['role']),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
