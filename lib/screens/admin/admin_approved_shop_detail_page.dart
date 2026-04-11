import 'package:flutter/material.dart';
import 'admin_detail_widgets.dart';

/// Read-only view of an approved shop owner.
class AdminApprovedShopDetailPage extends StatelessWidget {
  final Map<String, dynamic> shopData;
  const AdminApprovedShopDetailPage({super.key, required this.shopData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text(
          'Shop Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminDetailHeroCard(
            initial:
                ((shopData['shopName'] as String?) ?? 'S')[0].toUpperCase(),
            title: shopData['shopName'] ?? 'No Shop Name',
            subtitle: shopData['ownerName'] ?? '',
            accentColor: Colors.purple,
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 20),

          AdminDetailSectionHeader(
              title: 'Owner Information', icon: Icons.person),
          AdminDetailInfoRow(label: 'Owner Name', value: shopData['ownerName']),
          AdminDetailInfoRow(label: 'Email', value: shopData['email']),
          AdminDetailInfoRow(label: 'Phone', value: shopData['phone']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Shop Information', icon: Icons.store),
          AdminDetailInfoRow(label: 'Shop Name', value: shopData['shopName']),
          AdminDetailInfoRow(
              label: 'Shop Phone', value: shopData['shopPhone']),
          AdminDetailInfoRow(
              label: 'Building No.', value: shopData['shopAddress']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Location', icon: Icons.location_on_outlined),
          AdminDetailInfoRow(
              label: 'Governorate', value: shopData['governorate']),
          AdminDetailInfoRow(label: 'Wilayat', value: shopData['wilayat']),
          const SizedBox(height: 16),

          AdminDetailSectionHeader(
              title: 'Status', icon: Icons.verified_outlined),
          AdminDetailStatusChip(status: shopData['applicationStatus']),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
