import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database.dart';
import '../driver/driver_order_preview_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ShopOwnerOrdersPage extends StatefulWidget {
  const ShopOwnerOrdersPage({super.key});

  @override
  State<ShopOwnerOrdersPage> createState() => _ShopOwnerOrdersPageState();
}

class _ShopOwnerOrdersPageState extends State<ShopOwnerOrdersPage> {
  final String? shopId = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _sortAsc = false;   // false = newest first (default)

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chevron_left, size: 28, color: Colors.black87),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Orders',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      // Sort toggle
                      GestureDetector(
                        onTap: () => setState(() => _sortAsc = !_sortAsc),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Sort label
                  Text(
                    _sortAsc ? 'Oldest first' : 'Newest first',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10),

                  // ── Search Bar ───────────────────────────────────────────
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search order code or customer name...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Orders list ──────────────────────────────────────────────────
            Expanded(
              child: shopId == null
                  ? const Center(child: Text('Not logged in'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService().getShopOrdersStream(shopId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var docs = [...(snapshot.data?.docs ?? [])];

                        // Sort
                        docs.sort((a, b) {
                          final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
                          final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
                          if (aTs == null && bTs == null) return 0;
                          if (aTs == null) return 1;
                          if (bTs == null) return -1;
                          final cmp = (bTs as Timestamp).compareTo(aTs as Timestamp);
                          return _sortAsc ? -cmp : cmp;
                        });

                        // Filter by search query
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          docs = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final ref = (data['orderRef']?.toString() ?? '').toLowerCase();
                            final custName = (data['customerName']?.toString() ?? data['userName']?.toString() ?? '').toLowerCase();
                            return ref.contains(q) || custName.contains(q);
                          }).toList();
                        }

                        if (docs.isEmpty) return _buildEmptyState();

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final orderDoc = docs[index];
                            final orderData = orderDoc.data() as Map<String, dynamic>;
                            return _OrderTile(orderId: orderDoc.id, orderData: orderData);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No orders yet' : 'No matching orders found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty ? 'Orders will appear here once received.' : 'Try adjusting your search.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─── Order tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _OrderTile({required this.orderId, required this.orderData});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'order_placed':           return Colors.orange;
      case 'driver_assigned':            return Colors.blue;
      case 'heading_to_shop':         return Colors.orange.shade700;
      case 'at_shop_processing':       return Colors.indigo;
      case 'ready_for_pickup':             return Colors.teal;
      case 'driver_heading_to_shop_delivery': return Colors.teal.shade700;
      case 'heading_to_customer':  return Colors.purple;
      case 'completed':         return Colors.green;
      case 'overdue':           return Colors.red;
      default:                  return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'at_shop_processing':      return 'In Progress';
      case 'driver_heading_to_shop_delivery': return 'Driver Collecting';
      case 'heading_to_customer': return 'Out for Delivery';
      case 'overdue':          return 'Overdue';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : status;
    }
  }

  /// Format a Firestore Timestamp as e.g. "18 May 2026 · 14:32"
  String _formatTs(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final d = ts.toDate().toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final status       = orderData['status'] ?? 'order_placed';
    final customerName = orderData['customerName'] ?? orderData['userName'] ?? 'Customer';
    final totalPrice   = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final scheduledDate= orderData['scheduledDate'] ?? 'Not set';
    final createdAt    = orderData['createdAt'];
    final items        = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
    final statusColor  = _getStatusColor(status);

    return InkWell(
      onTap: () {
        OrderPreviewSheet.show(
          context,
          orderData: orderData,
          isPickup: true, // overridden by customTitle/Icon
          customTitle: 'Order Details',
          customIcon: Icons.receipt_long_rounded,
          customAccentColor: statusColor,
          isShopOwner: true,
          acceptButton: Builder(
            builder: (sheetContext) {
              return _buildActionSection(sheetContext, status, inSheet: true);
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: customer name, order ref + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${orderData['orderRef'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            // Row 2: placed date (createdAt)
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Placed: ${_formatTs(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),

            // Items
            Text('Items:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...items.map((item) {
              final name = item['serviceName'] ?? item['name'] ?? 'Service';
              final qty  = item['quantity'] ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${qty}x $name',
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Scheduled + Total
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Scheduled: $scheduledDate',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'OMR ${totalPrice.toStringAsFixed(3)}',
                  style: const TextStyle(
                      color: Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),

            // Action section
            _buildActionSection(context, status, inSheet: false),
          ],
        ),
      ),
    ));
  }

  Widget _buildActionSection(BuildContext context, String status, {bool inSheet = false}) {
    if (status == 'order_placed' || status == 'overdue') {
      return _statusRow(Icons.access_time_rounded, 'Awaiting Driver Pickup', Colors.orange.shade700);
    }
    if (status == 'driver_assigned') {
      return _statusRow(Icons.directions_car_rounded, 'Driver Collecting from Customer', Colors.blue);
    }
    if (status == 'heading_to_customer') {
      return _statusRow(Icons.local_shipping_rounded, 'Out for Delivery', Colors.purple);
    }
    if (status == 'completed') {
      return _statusRow(Icons.check_circle_rounded, 'Completed ✓', Colors.green);
    }
    if (status == 'ready_for_pickup') {
      return _statusRow(Icons.inventory_2_rounded, 'Ready — Awaiting Driver', Colors.teal);
    }
    if (status == 'driver_heading_to_shop_delivery') {
      return _statusRow(Icons.directions_car_rounded, 'Driver En Route to Collect', Colors.teal.shade700);
    }

    // Actionable: collected → in_progress → ready
    String buttonText = '';
    String nextStatus = '';
    String dialogTitle = '';
    String dialogBody = '';
    IconData dialogIcon = Icons.help_outline_rounded;
    Color dialogColor = Colors.black87;

    if (status == 'heading_to_shop') {
      buttonText   = 'Start Processing';
      nextStatus   = 'at_shop_processing';
      dialogTitle  = 'Start Processing?';
      dialogBody   = 'Are you sure the clothes have been received at the shop and you are ready to start cleaning?';
      dialogIcon   = Icons.local_laundry_service_rounded;
      dialogColor  = Colors.indigo;
    } else if (status == 'at_shop_processing') {
      buttonText   = 'Mark as Ready';
      nextStatus   = 'ready_for_pickup';
      dialogTitle  = 'Mark Order as Ready?';
      dialogBody   = 'Are you sure the laundry is fully cleaned and ready for the driver to pick up for delivery?';
      dialogIcon   = Icons.inventory_2_rounded;
      dialogColor  = Colors.teal;
    }

    if (nextStatus.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          // ── Confirmation dialog ──────────────────────────────────────────
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dialogColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(dialogIcon, color: dialogColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dialogTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                dialogBody,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Yes, Confirm'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;

          // ── Update status ────────────────────────────────────────────────
          try {
            await DatabaseService().updateOrderStatus(orderId, nextStatus);
            if (context.mounted) {
              if (inSheet) {
                Navigator.pop(context); // pop the bottom sheet
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Status updated to ${_formatStatus(nextStatus)}'),
                    ],
                  ),
                  backgroundColor: dialogColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update status: $e')),
              );
            }
          }
        },
        child: Text(buttonText,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }

  Widget _statusRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }
}
