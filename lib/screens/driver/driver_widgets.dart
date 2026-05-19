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

/// Relative time string — "just now", "5 min ago", "2 hr ago", "3 days ago"
String driverRelativeTime(dynamic timestamp) {
  if (timestamp is! Timestamp) return '';
  final diff = DateTime.now().difference(timestamp.toDate());
  if (diff.inSeconds < 60)  return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24)   return '${diff.inHours} hr ago';
  if (diff.inDays == 1)    return 'Yesterday';
  return '${diff.inDays} days ago';
}

/// Full formatted date string e.g. "18 May · 14:32"
String driverFullTime(dynamic timestamp) {
  if (timestamp is! Timestamp) return '—';
  final d = timestamp.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} · $h:$m';
}

Color driverStatusColor(String status) {
  switch (status) {
    case 'order_placed':          return Colors.orange;
    case 'driver_assigned':           return Colors.blue;
    case 'heading_to_shop':        return Colors.orange.shade700;
    case 'at_shop_processing':      return Colors.indigo;
    case 'ready_for_pickup':            return Colors.teal;
    case 'driver_heading_to_shop_delivery': return Colors.teal.shade700;
    case 'heading_to_customer': return Colors.purple;
    case 'completed':        return Colors.green;
    default:                 return Colors.grey;
  }
}

String driverStatusLabel(String status) {
  switch (status) {
    case 'at_shop_processing':      return 'In Progress';
    case 'driver_heading_to_shop_delivery': return 'Driver Collecting';
    case 'heading_to_customer': return 'Out for Delivery';
    case 'heading_to_shop':        return 'Heading to Shop';
    default:
      return status.isNotEmpty
          ? status[0].toUpperCase() + status.substring(1)
          : status;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// DriverOrderCard — social-media–style feed card
/// ─────────────────────────────────────────────────────────────────────────────

class DriverOrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Widget? actionWidget;
  /// Called when the card body is tapped (not the action button)
  final VoidCallback? onTap;

  const DriverOrderCard({
    super.key,
    required this.orderData,
    this.actionWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status        = orderData['status']        as String? ?? 'order_placed';
    final shopName      = orderData['shopName']      as String? ?? 'Unknown Shop';
    final customerName  = orderData['customerName']  as String? ?? 'Customer';
    final customerAddr  = _shortAddr(orderData);
    final totalPrice    = (orderData['totalPrice']   as num?)?.toDouble() ?? 0.0;
    final scheduledDate = orderData['scheduledDate'] as String? ?? '—';
    final createdAt     = orderData['createdAt'];
    final orderRef      = orderData['orderRef']      as String? ?? '';

    final statusColor = driverStatusColor(status);
    final relTime     = driverRelativeTime(createdAt);
    final fullTime    = driverFullTime(createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Accent top stripe with status + price ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      driverStatusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'OMR ${totalPrice.toStringAsFixed(3)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded,
                          size: 17, color: Colors.grey.shade500),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Customer name + area
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 17, color: Colors.grey.shade500),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          customerName,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  if (customerAddr.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.grey.shade400),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            customerAddr,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 15, color: Colors.grey.shade400),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          scheduledDate,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (orderRef.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.tag_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 7),
                        Text(
                          orderRef,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Action button ─────────────────────────────────────────────────
            if (actionWidget != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: SizedBox(width: double.infinity, child: actionWidget),
              ),
            ],

            // ── Social-post footer: relative time ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    relTime.isNotEmpty ? relTime : fullTime,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                  if (relTime.isNotEmpty && fullTime.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('·',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      fullTime,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade400),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 15, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortAddr(Map<String, dynamic> d) {
    final parts = [
      d['customerWilayat'],
      d['customerGov'],
    ].where((s) => s != null && s.toString().isNotEmpty).toList();
    return parts.join(', ');
  }
}
