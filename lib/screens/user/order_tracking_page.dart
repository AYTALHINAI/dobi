import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/user_theme.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';
import 'feedback_page.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Order status pipeline (matches the values stored in Firestore)
/// ─────────────────────────────────────────────────────────────────────────────
class _StatusStep {
  const _StatusStep({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
}

const _steps = [
  _StatusStep(
    key: 'order_placed',
    label: 'Order Placed',
    subtitle: 'Waiting for a driver to collect your laundry',
    icon: Icons.receipt_long_rounded,
  ),
  _StatusStep(
    key: 'driver_assigned',
    label: 'Driver Assigned',
    subtitle: 'A driver is heading to your location to collect the laundry',
    icon: Icons.shopping_bag_rounded,
  ),
  _StatusStep(
    key: 'heading_to_shop',
    label: 'Laundry Collected',
    subtitle: 'Driver collected your laundry — heading to the shop',
    icon: Icons.local_shipping_rounded,
  ),
  _StatusStep(
    key: 'at_shop_processing',
    label: 'Being Cleaned',
    subtitle: 'Your laundry is being washed and dried',
    icon: Icons.dry_cleaning_rounded,
  ),
  _StatusStep(
    key: 'ready_for_pickup',
    label: 'Ready for Delivery',
    subtitle: 'Cleaning done — awaiting delivery driver',
    icon: Icons.inventory_2_rounded,
  ),
  _StatusStep(
    key: 'driver_heading_to_shop_delivery',
    label: 'Driver Collecting',
    subtitle: 'Driver is heading to the shop to collect your clean clothes',
    icon: Icons.directions_car_rounded,
  ),
  _StatusStep(
    key: 'heading_to_customer',
    label: 'Out for Delivery',
    subtitle: 'Driver is on the way to you',
    icon: Icons.delivery_dining_rounded,
  ),
  _StatusStep(
    key: 'completed',
    label: 'Delivered',
    subtitle: 'Your clean laundry has arrived!',
    icon: Icons.check_circle_rounded,
  ),
];


// ─────────────────────────────────────────────────────────────────────────────
// OrderTrackingPage — live Firestore stream
// ─────────────────────────────────────────────────────────────────────────────

class OrderTrackingPage extends StatelessWidget {
  final String orderId;
  final bool fromPayment;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
    this.fromPayment = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !fromPayment,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (fromPayment) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userHome,
            (route) => false,
            arguments: 1, // UserOrdersPage index
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.uiBackground,
        appBar: AppBar(
          backgroundColor: context.uiBackground,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.uiTextPrimary),
            onPressed: () {
              if (fromPayment) {
                // Navigate back to UserMainPage (root) — lands on orders tab
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.userHome,
                  (route) => false,
                  arguments: 1,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Track Order',
            style: TextStyle(
              color: context.uiTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading order',
                  style: TextStyle(color: context.uiTextSecondary)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: context.uiPrimary));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('Order not found',
                  style: TextStyle(color: context.uiTextSecondary)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'order_placed';

          // ── Overdue detection ─────────────────────────────────────────────
          // An order is overdue when:
          // • It is still 'order_placed' (no driver has picked it up), AND
          // • The scheduled pickup date has passed
          final isOverdue = _checkOverdue(status, data);

          return _TrackingBody(
            orderId: orderId,
            data: data,
            status: status,
            isOverdue: isOverdue,
          );
        },
      ),
      ),
    );
  }

  /// Returns true when the order is pending past its scheduled window.
  bool _checkOverdue(String status, Map<String, dynamic> data) {
    if (status != 'order_placed') return false;
    // scheduledDate is a formatted string like:
    // "Friday, 16 May · Morning (8:00 AM – 12:00 PM)"
    // We use createdAt + 2 days as a simple overdue threshold when we
    // cannot parse the scheduled date string reliably.
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return false;
    final orderDate = createdAt.toDate();
    // If today is more than 1 day after the order was placed and it's
    // still pending, mark overdue.
    return DateTime.now().difference(orderDate).inHours > 36;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrackingBody — the actual page content
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.orderId,
    required this.data,
    required this.status,
    required this.isOverdue,
  });

  final String orderId;
  final Map<String, dynamic> data;
  final String status;
  final bool isOverdue;

  int get _currentIndex {
    if (isOverdue) return 0; // stuck at pending
    final idx = _steps.indexWhere((s) => s.key == status);
    return idx < 0 ? 0 : idx;
  }

  bool get _isDelivered => status == 'completed';

  @override
  Widget build(BuildContext context) {
    final orderRef     = data['orderRef']     as String? ?? '—';
    final shopName     = data['shopName']     as String? ?? 'Unknown Shop';
    final scheduledDate= data['scheduledDate']as String? ?? 'Not set';
    final totalPrice   = (data['totalPrice']  as num?)?.toDouble() ?? 0.0;
    final items        = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final paymentStatus= data['paymentStatus']as String? ?? 'unpaid';
    final refundRequested = data['refundRequested'] == true;
    // Contact info
    final shopPhone    = data['shopPhone']    as String? ?? '';
    final driverPhone  = data['driverPhone']  as String? ?? '';
    final driverName   = data['driverName']   as String? ?? 'Driver';
    final hasDriver    = driverPhone.isNotEmpty || ["picked", "collected", "out_for_delivery"].contains(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order reference header ────────────────────────────────────────
          _RefHeader(orderRef: orderRef, shopName: shopName),
          const SizedBox(height: 20),

          // ── Overdue banner ─────────────────────────────────────────────────
          if (isOverdue) ...[
            _OverdueBanner(
              orderId: orderId,
              refundRequested: refundRequested,
            ),
            const SizedBox(height: 20),
          ],

          // ── Talabat-style vertical stepper ────────────────────────────────
          if (!isOverdue) ...[
            Text('Order Progress',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.uiTextPrimary)),
            const SizedBox(height: 16),
            _VerticalStepper(currentIndex: _currentIndex, isDelivered: _isDelivered),
            const SizedBox(height: 24),
          ],

          // ── Contact section (visible once a driver is assigned) ──────────────
          if (hasDriver) ...[
            _ContactCard(
              shopName:    shopName,
              shopPhone:   shopPhone,
              driverName:  driverName,
              driverPhone: driverPhone,
              status:      status,
            ),
            const SizedBox(height: 20),
          ],


          // ── Scheduled pickup ───────────────────────────────────────────────
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Scheduled Pickup',
            value: scheduledDate,
          ),
          const SizedBox(height: 12),

          // ── Items breakdown ────────────────────────────────────────────────
          Text('Items',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.uiTextPrimary)),
          const SizedBox(height: 12),
          _ItemsCard(items: items),
          const SizedBox(height: 16),

          // ── Total + payment ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.uiTextPrimary)),
              Text('${totalPrice.toStringAsFixed(3)} OMR',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.uiPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment',
                  style: TextStyle(fontSize: 14, color: context.uiTextSecondary)),
              _PaymentBadge(status: paymentStatus),
            ],
          ),
          const SizedBox(height: 32),

          // ── Rate button (delivered only) ──────────────────────────────────
          if (_isDelivered && data['feedbackGiven'] != true)
            _RateButton(orderId: orderId, data: data),
          if (_isDelivered && data['feedbackGiven'] == true)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showFeedbackBottomSheet(context, orderId, shopName),
                child: Text(
                  'View Feedback',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.uiTextPrimary),
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showFeedbackBottomSheet(BuildContext context, String orderId, String shopName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot?>(
          future: DatabaseService().getFeedbackForOrder(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: context.uiSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: context.uiSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Text('Feedback not found', style: TextStyle(color: context.uiTextPrimary)),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final rating = data['rating']?.toString() ?? '0';
            final comment = data['comment']?.toString() ?? '';
            final shopReply = data['shopReply']?.toString();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.uiSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Feedback',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.uiTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF5C518), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        rating,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.uiTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (comment.isNotEmpty)
                    Text(
                      comment,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.uiTextSecondary,
                      ),
                    ),
                  if (shopReply != null && shopReply.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade900 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.uiDivider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reply from $shopName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.uiTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shopReply,
                            style: TextStyle(
                              fontSize: 15,
                              color: context.uiTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RefHeader
// ─────────────────────────────────────────────────────────────────────────────

class _RefHeader extends StatelessWidget {
  const _RefHeader({required this.orderRef, required this.shopName});
  final String orderRef;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.uiDivider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.uiPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, color: context.uiPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.uiTextPrimary)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: orderRef));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order reference copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(orderRef,
                          style: TextStyle(
                              fontSize: 13,
                              color: context.uiPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      Icon(Icons.copy_rounded, size: 13, color: context.uiPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VerticalStepper — Talabat-style vertical timeline
// ─────────────────────────────────────────────────────────────────────────────

class _VerticalStepper extends StatelessWidget {
  const _VerticalStepper({required this.currentIndex, required this.isDelivered});
  final int currentIndex;
  final bool isDelivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.uiDivider),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final step       = _steps[i];
          final isCompleted= i <= currentIndex;
          final isCurrent  = i == currentIndex;
          final isLast     = i == _steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: circle + connector line ────────────────────────────
              Column(
                children: [
                  // Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? (isLast && isDelivered ? Colors.green : context.uiPrimary)
                          : context.uiBackground,
                      border: Border.all(
                        color: isCompleted
                            ? (isLast && isDelivered ? Colors.green : context.uiPrimary)
                            : context.uiDivider,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      size: 16,
                      color: isCompleted ? Colors.white : context.uiTextHint,
                    ),
                  ),
                  // Connector
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 2,
                      height: 40,
                      color: i < currentIndex
                          ? context.uiPrimary
                          : context.uiDivider,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // ── Right: label + subtitle ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: isLast ? 0 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCompleted
                                  ? context.uiTextPrimary
                                  : context.uiTextHint,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.uiPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(step.subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: isCompleted
                                  ? context.uiTextSecondary
                                  : context.uiTextHint)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OverdueBanner — shown when order is stuck in pending past pickup time
// ─────────────────────────────────────────────────────────────────────────────

class _OverdueBanner extends StatefulWidget {
  const _OverdueBanner({required this.orderId, required this.refundRequested});
  final String orderId;
  final bool refundRequested;

  @override
  State<_OverdueBanner> createState() => _OverdueBannerState();
}

class _OverdueBannerState extends State<_OverdueBanner> {
  bool _requesting = false;

  Future<void> _requestRefund() async {
    setState(() => _requesting = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'overdue',
        'refundRequested': true,
        'refundRequestedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund request submitted. We\'ll review it within 24 hours.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text('Pickup Overdue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange.shade800,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No driver has picked up your order past the scheduled window. '
            'You may request a full refund or wait for a driver to become available.',
            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 14),
          if (widget.refundRequested)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Refund request submitted — under review',
                      style: TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requesting ? null : _requestRefund,
                icon: _requesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.account_balance_wallet_rounded, size: 18),
                label: Text(_requesting ? 'Submitting…' : 'Request a Refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ItemsCard
// ─────────────────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.uiDivider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(color: context.uiDivider, height: 1),
        itemBuilder: (context, i) {
          final item  = items[i];
          final name  = item['serviceName'] ?? 'Service';
          final qty   = item['quantity']    ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${qty}x $name',
                    style: TextStyle(
                        fontSize: 14, color: context.uiTextPrimary)),
                Text('${(price * qty).toStringAsFixed(3)} OMR',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.uiTextPrimary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoRow
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.uiPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: context.uiTextSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.uiTextPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaymentBadge
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid  = status == 'paid';
    final color   = isPaid ? Colors.green : Colors.redAccent;
    final label   = isPaid ? 'Paid ✓' : status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RateButton
// ─────────────────────────────────────────────────────────────────────────────

class _RateButton extends StatelessWidget {
  const _RateButton({required this.orderId, required this.data});
  final String orderId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            userPageRoute((_) => FeedbackPage(
              orderId: orderId,
              shopId:  data['shopId']  ?? '',
              shopName: data['shopName'] ?? 'Shop',
            )),
          );
        },
        icon: const Icon(Icons.star_rounded),
        label: const Text('Rate This Order'),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.uiPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ContactCard — call / WhatsApp shop & driver
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.shopName,
    required this.shopPhone,
    required this.driverName,
    required this.driverPhone,
    required this.status,
  });

  final String shopName;
  final String shopPhone;
  final String driverName;
  final String driverPhone;
  final String status;

  // Show the driver row only when a driver is actually on the move
  bool get _showDriver =>
      driverPhone.isNotEmpty &&
      ['driver_assigned', 'heading_to_shop', 'heading_to_customer'].contains(status);

  Future<void> _call(BuildContext context, String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    }
  }

  Future<void> _whatsapp(BuildContext context, String phone) async {
    if (phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.uiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.uiTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ── Laundry shop row ───────────────────────────────────────────────
          _ContactRow(
            icon: Icons.storefront_rounded,
            iconColor: context.uiPrimary,
            title: shopName,
            subtitle: 'Laundry Shop',
            phone: shopPhone,
            onCall:      shopPhone.isNotEmpty ? () => _call(context, shopPhone)      : null,
            onWhatsApp:  shopPhone.isNotEmpty ? () => _whatsapp(context, shopPhone)  : null,
          ),

          // ── Driver row (only when driver is active) ────────────────────────
          if (_showDriver) ...[
            const Divider(height: 20),
            _ContactRow(
              icon: Icons.delivery_dining_rounded,
              iconColor: Colors.blue.shade700,
              title: driverName.isNotEmpty ? driverName : 'Your Driver',
              subtitle: 'Delivery Driver',
              phone: driverPhone,
              onCall:     () => _call(context, driverPhone),
              onWhatsApp: () => _whatsapp(context, driverPhone),
            ),
          ],
        ],
      ),
    );
  }
}

// Single contact row with call + WhatsApp buttons
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.onCall,
    required this.onWhatsApp,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String phone;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.uiTextPrimary)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: context.uiTextSecondary)),
            ],
          ),
        ),
        // Call button
        if (onCall != null)
          _IconBtn(
            onTap: onCall!,
            icon: Icons.phone_rounded,
            color: Colors.green.shade700,
          ),
        if (onCall != null) const SizedBox(width: 8),
        // WhatsApp button
        if (onWhatsApp != null)
          InkWell(
            onTap: onWhatsApp,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const _TrackingWhatsAppIcon(),
            ),
          ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.onTap, required this.icon, required this.color});
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// Pure-Flutter WhatsApp brand icon
class _TrackingWhatsAppIcon extends StatelessWidget {
  const _TrackingWhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Center(
        child: Text(
          'W',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
