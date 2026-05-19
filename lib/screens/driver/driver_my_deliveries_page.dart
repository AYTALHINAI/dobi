import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'driver_widgets.dart';

class DriverMyDeliveriesPage extends StatelessWidget {
  final String uid;
  const DriverMyDeliveriesPage({super.key, required this.uid});

  List<QueryDocumentSnapshot> _sorted(List<QueryDocumentSnapshot> raw) {
    return [...raw]..sort((a, b) {
        final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
        final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return (bTs as Timestamp).compareTo(aTs as Timestamp);
      });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereIn: ['driver_assigned', 'heading_to_shop', 'driver_heading_to_shop_delivery', 'heading_to_customer'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black87));
        }

        final allDocs = _sorted(snapshot.data?.docs ?? []);
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['pickupDriverId'] == uid || data['driverId'] == uid;
        }).toList();

        if (docs.isEmpty) {
          return buildDriverEmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No Active Jobs',
            subtitle: 'Accept a pickup or delivery from the Available tab.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final orderDoc = docs[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            return _ActiveJobCard(
                orderDoc: orderDoc, orderData: orderData, driverUid: uid);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActiveJobCard — full market-standard delivery card
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveJobCard extends StatefulWidget {
  const _ActiveJobCard({
    required this.orderDoc,
    required this.orderData,
    required this.driverUid,
  });
  final QueryDocumentSnapshot orderDoc;
  final Map<String, dynamic> orderData;
  final String driverUid;

  @override
  State<_ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends State<_ActiveJobCard> {
  bool _markingDelivered  = false;
  bool _confirmingCollect = false;

  String get status => widget.orderData['status'] ?? 'driver_assigned';
  bool get isPickupLeg => status == 'driver_assigned' || status == 'heading_to_shop';
  bool get isCollected => status == 'heading_to_shop';

  // ── Colour & label helpers ─────────────────────────────────────────────────
  Color get _accentColor {
    if (status == 'heading_to_customer') return Colors.teal;
    if (status == 'driver_heading_to_shop_delivery') return Colors.teal.shade700;
    if (status == 'heading_to_shop') return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  String get _legLabel {
    if (status == 'heading_to_customer') return 'Delivery Leg';
    if (status == 'driver_heading_to_shop_delivery') return 'Heading to Shop (Delivery)';
    if (status == 'heading_to_shop') return 'Heading to Shop (Pickup)';
    return 'Pickup Leg';
  }

  // ── Open Google Maps — customer address ───────────────────────────────────
  Future<void> _openCustomerMaps() async {
    final lat = widget.orderData['customerLatitude'];
    final lng = widget.orderData['customerLongitude'];
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    } else {
      final address = [
        widget.orderData['customerAddress'],
        widget.orderData['customerWilayat'],
        widget.orderData['customerGov'],
        'Oman',
      ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  // ── Open Google Maps — shop address ───────────────────────────────────────
  Future<void> _openShopMaps() async {
    final lat = widget.orderData['shopLatitude'];
    final lng = widget.orderData['shopLongitude'];
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    } else {
      final address = [
        widget.orderData['shopAddress'],
        widget.orderData['shopWilayat'],
        widget.orderData['shopGovernorate'],
        'Oman',
      ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  // ── Call customer ──────────────────────────────────────────────────────────
  Future<void> _callCustomer() async {
    final phone = widget.orderData['customerPhone']?.toString() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── WhatsApp customer ──────────────────────────────────────────────────────
  Future<void> _whatsappCustomer() async {
    final raw = widget.orderData['customerPhone']?.toString() ?? '';
    if (raw.isEmpty) return;
    // Strip everything except digits, then build the wa.me link
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  // ── Call shop ──────────────────────────────────────────────────────────────
  Future<void> _callShop() async {
    final phone = widget.orderData['shopPhone']?.toString() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── WhatsApp shop ──────────────────────────────────────────────────────────
  Future<void> _whatsappShop() async {
    final raw = widget.orderData['shopPhone']?.toString() ?? '';
    if (raw.isEmpty) return;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  // ── Confirm collected from customer ────────────────────────────────────────
  Future<void> _confirmCollected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text('Confirm Collection?'),
          ],
        ),
        content: const Text(
          'Have you collected the laundry from the customer?\n\n'
          'Tapping confirm will notify the customer and update the order status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Collected'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirmingCollect = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDoc.id)
          .update({
        'status': 'heading_to_shop',
        'collectedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great! Now head to the laundry shop.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _confirmingCollect = false);
    }
  }

  // ── Confirm collected from shop (Delivery Leg) ─────────────────────────────
  Future<void> _confirmCollectedFromShop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Colors.teal, size: 22),
            SizedBox(width: 10),
            Text('Confirm Collection?'),
          ],
        ),
        content: const Text(
          'Have you collected the fresh laundry from the shop?\n\n'
          'Tapping confirm will notify the customer that you are on the way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Collected'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirmingCollect = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDoc.id)
          .update({
        'status': 'heading_to_customer',
        'shopCollectedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great! Now head to the customer.'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _confirmingCollect = false);
    }
  }

  // ── Mark as delivered ──────────────────────────────────────────────────────
  Future<void> _markDelivered() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delivery'),
        content:
            const Text('Mark this order as delivered to the customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _markingDelivered = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDoc.id)
          .update({
        'status': 'completed',
        'deliveredAt': Timestamp.now(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _markingDelivered = false);
    }
  }

  // ── Format timestamp ───────────────────────────────────────────────────────
  String _formatTs(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final hour = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '${d.day}/${d.month}/${d.year}  $hour:$min';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final orderRef     = widget.orderData['orderRef']       ?? '—';
    final shopName     = widget.orderData['shopName']        ?? 'Unknown Shop';
    final customerName = widget.orderData['customerName']    ?? 'Customer';
    final customerPhone= widget.orderData['customerPhone']   ?? '';
    final customerAddr = [
      widget.orderData['customerAddress'],
      widget.orderData['customerWilayat'],
      widget.orderData['customerGov'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
    final shopAddr = [
      widget.orderData['shopAddress'],
      widget.orderData['shopWilayat'],
      widget.orderData['shopGovernorate'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
    final totalPrice  = (widget.orderData['totalPrice'] ?? 0.0).toDouble();
    final scheduledDate = widget.orderData['scheduledDate'] ?? '—';
    final createdAt   = widget.orderData['createdAt'];
    final items       = (widget.orderData['items'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                      status == 'heading_to_customer'
                          ? Icons.delivery_dining_rounded
                          : (status == 'heading_to_shop' || status == 'driver_heading_to_shop_delivery')
                              ? Icons.local_shipping_rounded
                              : Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_legLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      // Order ref chip
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: orderRef));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order code copied!'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(orderRef,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5)),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_rounded,
                                  color: Colors.white70, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer & Shop row ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.person_outline_rounded,
                        label: 'Customer',
                        value: customerName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.storefront_rounded,
                        label: 'Laundry Shop',
                        value: shopName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Location cards — always show BOTH ───────────────────────
                _sectionTitle('Locations'),
                const SizedBox(height: 10),

                // Customer address card
                _DestinationCard(
                  label: "📍 Customer's Address",
                  icon: Icons.home_rounded,
                  address: customerAddr,
                  accentColor: Colors.blue.shade700,
                  onNavigate: _openCustomerMaps,
                  // Current stop on 'driver_assigned' (pickup) or 'heading_to_customer' (delivery)
                  isCurrentLeg: status == 'driver_assigned' || status == 'heading_to_customer',
                ),
                const SizedBox(height: 10),

                // Shop address card
                _DestinationCard(
                  label: '🏪 Laundry Shop',
                  icon: Icons.store_rounded,
                  address: shopAddr,
                  accentColor: Colors.teal,
                  onNavigate: _openShopMaps,
                  // Current stop on 'heading_to_shop' (dropoff) or 'driver_heading_to_shop_delivery' (pickup clean)
                  isCurrentLeg: status == 'heading_to_shop' || status == 'driver_heading_to_shop_delivery',
                ),
                const SizedBox(height: 14),

                // ── Order details ────────────────────────────────────────────
                _sectionTitle('Order Details'),
                const SizedBox(height: 8),
                _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Scheduled',
                    value: scheduledDate),
                _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Placed',
                    value: _formatTs(createdAt)),
                _DetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Total',
                    value: 'OMR ${totalPrice.toStringAsFixed(3)}',
                    valueColor: Colors.green.shade700,
                    bold: true),

                // ── Items breakdown ──────────────────────────────────────────
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionTitle('Items'),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final name = item['name'] ?? item['serviceName'] ?? 'Item';
                    final qty  = item['quantity'] ?? 1;
                    final price= (item['price'] ?? 0.0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 10, top: 2),
                            decoration: BoxDecoration(
                                color: _accentColor, shape: BoxShape.circle),
                          ),
                          Expanded(
                              child: Text('$name × $qty',
                                  style: const TextStyle(fontSize: 13))),
                          Text('OMR ${price.toStringAsFixed(3)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // ── Action buttons ───────────────────────────────────────────
                if (status == 'driver_assigned') ...[
                  // STEP 1: Pickup leg — go collect from customer
                  Row(
                    children: [
                      if (customerPhone.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text('Call Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              side: BorderSide(color: Colors.blue.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      if (customerPhone.isNotEmpty) const SizedBox(width: 10),
                      // WhatsApp button
                      if (customerPhone.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _whatsappCustomer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WhatsAppIcon(),
                                SizedBox(width: 6),
                                Text('WhatsApp Cust.',
                                    style: TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Confirm collected button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmingCollect ? null : _confirmCollected,
                      icon: _confirmingCollect
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.inventory_2_rounded, size: 18),
                      label: Text(_confirmingCollect
                          ? 'Confirming...'
                          : 'Collected from Customer ✓'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (status == 'heading_to_shop') ...[
                  // STEP 2: Heading to shop — Shop contact above Customer contact
                  Builder(builder: (context) {
                    final shopPhone = widget.orderData['shopPhone']?.toString() ?? '';
                    if (shopPhone.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callShop,
                                icon: const Icon(Icons.phone_rounded, size: 16),
                                label: const Text('Call Shop'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.indigo.shade700,
                                  side: BorderSide(color: Colors.indigo.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _whatsappShop,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _WhatsAppIcon(),
                                    SizedBox(width: 6),
                                    Text('WhatsApp Shop', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                  
                  if (customerPhone.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text('Call Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _whatsappCustomer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WhatsAppIcon(),
                                SizedBox(width: 6),
                                Text('WhatsApp Cust.', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Navigate to shop
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openShopMaps,
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Navigate to Shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drop off the laundry at the shop. The shop owner will take it from here.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (status == 'driver_heading_to_shop_delivery') ...[
                  // STEP 3a: Heading to shop (Delivery Leg) — Shop contact above Customer contact
                  Builder(builder: (context) {
                    final shopPhone = widget.orderData['shopPhone']?.toString() ?? '';
                    if (shopPhone.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callShop,
                                icon: const Icon(Icons.phone_rounded, size: 16),
                                label: const Text('Call Shop'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.indigo.shade700,
                                  side: BorderSide(color: Colors.indigo.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _whatsappShop,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _WhatsAppIcon(),
                                    SizedBox(width: 6),
                                    Text('WhatsApp Shop', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                  
                  if (customerPhone.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text('Call Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _whatsappCustomer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WhatsAppIcon(),
                                SizedBox(width: 6),
                                Text('WhatsApp Cust.', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Confirm collected from shop button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmingCollect ? null : _confirmCollectedFromShop,
                      icon: _confirmingCollect
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.inventory_2_rounded, size: 18),
                      label: Text(_confirmingCollect
                          ? 'Confirming...'
                          : 'Collected from Shop ✓'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pick up the fresh laundry from the shop and then head to the customer.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // STEP 3b: Delivery leg — Shop contact above Customer contact
                  Builder(builder: (context) {
                    final shopPhone = widget.orderData['shopPhone']?.toString() ?? '';
                    if (shopPhone.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _callShop,
                                icon: const Icon(Icons.phone_rounded, size: 16),
                                label: const Text('Call Shop'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal.shade700,
                                  side: BorderSide(color: Colors.teal.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _whatsappShop,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _WhatsAppIcon(),
                                    SizedBox(width: 6),
                                    Text('WhatsApp Shop', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),

                  Row(
                    children: [
                      if (customerPhone.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text('Call Customer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side:
                                  BorderSide(color: Colors.teal.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      if (customerPhone.isNotEmpty) const SizedBox(width: 10),
                      // WhatsApp button
                      if (customerPhone.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _whatsappCustomer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              side: const BorderSide(color: Color(0xFF25D366)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WhatsAppIcon(),
                                SizedBox(width: 6),
                                Text('WhatsApp Cust.',
                                    style: TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _markingDelivered ? null : _markDelivered,
                      icon: _markingDelivered
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(_markingDelivered
                          ? 'Marking...'
                          : 'Mark as Delivered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.5),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _DestinationCard — map preview card with Navigate button
// ─────────────────────────────────────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.label,
    required this.icon,
    required this.address,
    required this.accentColor,
    required this.onNavigate,
    this.isCurrentLeg = false,
  });
  final String label;
  final IconData icon;
  final String address;
  final Color accentColor;
  final VoidCallback onNavigate;
  final bool isCurrentLeg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNavigate,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrentLeg
              ? accentColor.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentLeg
                ? accentColor.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isCurrentLeg ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: isCurrentLeg
                      ? accentColor.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle),
              child: Icon(icon,
                  color: isCurrentLeg ? accentColor : Colors.grey.shade500,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              color: isCurrentLeg
                                  ? accentColor
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3)),
                      if (isCurrentLeg) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Current Stop',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.isNotEmpty ? address : 'Address not available',
                    style: TextStyle(
                        fontSize: 13,
                        color: isCurrentLeg
                            ? Colors.grey.shade800
                            : Colors.grey.shade500,
                        fontWeight: isCurrentLeg
                            ? FontWeight.w500
                            : FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isCurrentLeg ? accentColor : Colors.grey.shade300,
                  shape: BoxShape.circle),
              child: Icon(Icons.navigation_rounded,

                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoBlock — small label+value tile
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  const _InfoBlock(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow — icon + label + value row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: valueColor ?? Colors.black87,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WhatsAppIcon — pure-Flutter WhatsApp brand icon (no assets / no network)
// ─────────────────────────────────────────────────────────────────────────────

class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();
  final double size = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          'W',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.65,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
