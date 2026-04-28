import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reusable empty-state widget for driver tabs.
Widget buildDriverEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Reusable order card shared by all 3 driver tabs.
class DriverOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Widget? actionWidget;

  const DriverOrderCard({
    super.key,
    required this.orderData,
    this.actionWidget,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':    return Colors.orange;
      case 'picked':     return Colors.blue;
      case 'in_progress':return Colors.indigo;
      case 'ready':      return Colors.teal;
      case 'delivered':  return Colors.green;
      default:           return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : status;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final d = timestamp.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return 'Unknown date';
  }

  @override
  Widget build(BuildContext context) {
    final status        = orderData['status']       ?? 'pending';
    final shopName      = orderData['shopName']     ?? 'Unknown Shop';
    final customerName  = orderData['customerName'] ?? 'Customer';
    final scheduledDate = orderData['scheduledDate']?? 'Unknown Date';
    final totalPrice    = orderData['totalPrice']   ?? 0.0;
    final dateStr = orderData['createdAt'] != null
        ? _formatDate(orderData['createdAt'])
        : scheduledDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: status badge + price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'RM ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Shop name
          Row(
            children: [
              const Icon(Icons.storefront, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer name
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Scheduled / delivered date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == 'delivered'
                      ? 'Delivered: $dateStr'
                      : 'Scheduled: $scheduledDate',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          if (actionWidget != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            SizedBox(width: double.infinity, child: actionWidget),
          ],
        ],
      ),
    );
  }
}
