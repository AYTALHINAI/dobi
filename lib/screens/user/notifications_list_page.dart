import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
import 'order_tracking_page.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  final _db = DatabaseService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    if (_uid == null) return;
    try {
      await _db.markNotificationsAsRead(_uid!);
    } catch (_) {}
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'order_placed':
        return Icons.receipt_long_rounded;
      case 'driver_assigned':
        return Icons.shopping_bag_rounded;
      case 'heading_to_shop':
        return Icons.local_shipping_rounded;
      case 'at_shop_processing':
        return Icons.dry_cleaning_rounded;
      case 'ready_for_pickup':
        return Icons.inventory_2_rounded;
      case 'driver_heading_to_shop_delivery':
        return Icons.directions_car_rounded;
      case 'heading_to_customer':
        return Icons.delivery_dining_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getStatusColor(String? status, BuildContext context) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'order_placed':
        return Colors.orange;
      default:
        return context.uiPrimary;
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.uiPrimary;
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.uiTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: context.uiTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getUserNotificationsStream(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: context.uiTextSecondary),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.uiTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You will see laundry updates and notifications here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.uiTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Notification';
              final body = data['body'] ?? '';
              final status = data['status'] as String?;
              final orderId = data['orderId'] as String?;
              final createdAt = data['createdAt'] as Timestamp?;
              final isRead = data['isRead'] as bool? ?? false;

              final statusColor = _getStatusColor(status, context);

              return InkWell(
                onTap: () {
                  if (orderId != null && orderId.isNotEmpty) {
                    Navigator.push(
                      context,
                      userPageRoute((_) => OrderTrackingPage(orderId: orderId)),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.uiSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? context.uiDivider : primary.withOpacity(0.2),
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      color: context.uiTextPrimary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.uiTextSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTimestamp(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.uiTextHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
