import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../database.dart';
import 'driver_order_preview_sheet.dart';
import 'driver_widgets.dart';

// ── Oman Governorate → Wilayat map ────────────────────────────────────────────
const Map<String, List<String>> _governorateWilayatMap = {
  'Muscat': ['Muttrah', 'Bawshar', 'Seeb', 'Al Amerat', 'Qurayyat'],
  'Dhofar': ['Salalah', 'Taqah', 'Mirbat', 'Thumrait', 'Sadah', 'Rakhyut', 'Dalkut', 'Muqshin'],
  'Musandam': ['Khasab', 'Bukha', 'Dibba Al Baya', 'Madha'],
  'Al Buraimi': ['Mahdah', 'Al Sinainah'],
  'Al Dakhiliyah': ['Nizwa', 'Bahla', 'Adam', 'Izki', 'Samail', 'Bidbid', 'Manah'],
  'Al Dhahirah': ['Ibri', 'Yanqul', 'Dhank'],
  'North Al Batinah': ['Sohar', 'Shinas', 'Liwa', 'Saham', 'Al Khaburah', 'Suwaiq'],
  'South Al Batinah': ['Rustaq', 'Nakhal', 'Wadi Al Maawil', 'Barka', 'Al Musannah'],
  'North Al Sharqiyah': ['Ibra', 'Al Mudhaibi', 'Bidiyah', 'Qabil', 'Wadi Bani Khalid', 'Dema Wa Thaieen'],
  'South Al Sharqiyah': ['Sur', 'Jalan Bani Bu Ali', 'Jalan Bani Bu Hassan', 'Al Kamil Wal Wafi', 'Masirah'],
  'Al Wusta': ['Haima', 'Duqm', 'Mahout', 'Al Jazer'],
};

class DriverAvailableOrdersPage extends StatefulWidget {
  final String uid;
  final VoidCallback? onNavigateToDeliveries;
  const DriverAvailableOrdersPage({super.key, required this.uid, this.onNavigateToDeliveries});

  @override
  State<DriverAvailableOrdersPage> createState() =>
      _DriverAvailableOrdersPageState();
}

class _DriverAvailableOrdersPageState
    extends State<DriverAvailableOrdersPage> {
  String? _selectedGovernorate;
  String? _selectedWilayat;

  List<String> get _governorates => _governorateWilayatMap.keys.toList();
  List<String> get _wilayats => _selectedGovernorate != null
      ? _governorateWilayatMap[_selectedGovernorate]!
      : [];

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    if (_selectedGovernorate == null && _selectedWilayat == null) return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Check shop location
      final shopGov = (data['shopGovernorate'] ?? '').toString().toLowerCase();
      final shopWil = (data['shopWilayat']     ?? '').toString().toLowerCase();

      // Check customer location (stored when user registered their location)
      final custGov = (data['customerGovernorate'] ??
                       data['governorate']          ??
                       '').toString().toLowerCase();
      final custWil = (data['customerWilayat'] ??
                       data['wilayat']          ??
                       '').toString().toLowerCase();

      // A match on EITHER shop OR customer location passes the filter
      final selGov = _selectedGovernorate?.toLowerCase();
      final selWil = _selectedWilayat?.toLowerCase();

      final govMatch = selGov == null ||
          shopGov == selGov ||
          custGov == selGov;

      final wilMatch = selWil == null ||
          shopWil == selWil ||
          custWil == selWil;

      return govMatch && wilMatch;
    }).toList();
  }

  /// Returns true if the driver already has an active order (picked or out_for_delivery).
  bool _driverHasActiveOrder(List<QueryDocumentSnapshot> allActiveOrders) {
    return allActiveOrders.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['pickupDriverId'] == widget.uid ||
          data['driverId'] == widget.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          // Outer stream: check if this driver has any active order right now
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: ['driver_assigned', 'heading_to_shop', 'driver_heading_to_shop_delivery', 'heading_to_customer'])
                .snapshots(),
            builder: (context, activeSnap) {
              final activeOrders = activeSnap.data?.docs ?? [];
              final hasActiveOrder = _driverHasActiveOrder(activeOrders);

              return StreamBuilder<QuerySnapshot>(
                stream: DatabaseService().getDriverPickupAndDeliveryOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black87),
                    );
                  }

                  // Sort newest-first, then filter by governorate/wilayat
                  final rawDocs = <QueryDocumentSnapshot>[...(snapshot.data?.docs ?? [])];
                  rawDocs.sort((a, b) {
                    final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
                    final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return (bTs as Timestamp).compareTo(aTs as Timestamp);
                  });
                  final allDocs = _filter(rawDocs);
                  final pickupOrders = allDocs
                      .where((d) =>
                          (d.data() as Map<String, dynamic>)['status'] ==
                          'order_placed')
                      .toList();
                  final deliveryOrders = allDocs
                      .where((d) =>
                          (d.data() as Map<String, dynamic>)['status'] ==
                          'ready_for_pickup')
                      .toList();

                  if (pickupOrders.isEmpty && deliveryOrders.isEmpty) {
                    return buildDriverEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No Available Orders',
                      subtitle:
                          'Pending pickups and ready deliveries will appear here.',
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // ── Active order banner ─────────────────────────────────
                      if (hasActiveOrder)
                        _ActiveOrderBanner(uid: widget.uid),

                      // ── PICKUPS (collapsible) ────────────────────────────
                      if (pickupOrders.isNotEmpty)
                        _SectionDropdown(
                          label: 'Pickups from Customers',
                          icon: Icons.shopping_bag_rounded,
                          color: Colors.blue,
                          subtitle: 'Collect dirty laundry — drop off at the shop',
                          count: pickupOrders.length,
                          children: pickupOrders.map((orderDoc) {
                            final orderData =
                                orderDoc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DriverOrderCard(
                                orderData: orderData,
                                onTap: () => OrderPreviewSheet.show(
                                  context,
                                  orderData:    orderData,
                                  isPickup:     true,
                                  acceptButton: hasActiveOrder
                                      ? _lockedBanner()
                                      : _PickupButton(
                                          orderId:   orderDoc.id,
                                          driverUid: widget.uid,
                                          disabled:  false,
                                          onNavigateToDeliveries: widget.onNavigateToDeliveries,
                                        ),
                                ),
                                actionWidget: _PickupButton(
                                  orderId:   orderDoc.id,
                                  driverUid: widget.uid,
                                  disabled:  hasActiveOrder,
                                  onNavigateToDeliveries: widget.onNavigateToDeliveries,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      // ── DELIVERIES (collapsible) ─────────────────────────
                      if (deliveryOrders.isNotEmpty) ...[
                        if (pickupOrders.isNotEmpty) const SizedBox(height: 8),
                        _SectionDropdown(
                          label: 'Deliveries to Customers',
                          icon: Icons.delivery_dining_rounded,
                          color: Colors.teal,
                          subtitle: 'Pick up clean laundry — deliver to customer',
                          count: deliveryOrders.length,
                          children: deliveryOrders.map((orderDoc) {
                            final orderData =
                                orderDoc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DriverOrderCard(
                                orderData: orderData,
                                onTap: () => OrderPreviewSheet.show(
                                  context,
                                  orderData:    orderData,
                                  isPickup:     false,
                                  acceptButton: hasActiveOrder
                                      ? _lockedBanner()
                                      : _DeliveryButton(
                                          orderId:   orderDoc.id,
                                          driverUid: widget.uid,
                                          disabled:  false,
                                          onNavigateToDeliveries: widget.onNavigateToDeliveries,
                                        ),
                                ),
                                actionWidget: _DeliveryButton(
                                  orderId:   orderDoc.id,
                                  driverUid: widget.uid,
                                  disabled:  hasActiveOrder,
                                  onNavigateToDeliveries: widget.onNavigateToDeliveries,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Lottie.asset('assets/Globe.json',
                    repeat: true, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Orders',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Filter by area to find nearby jobs',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _selectedGovernorate,
            hint: 'All Governorates',
            icon: Icons.map_rounded,
            items: _governorates,
            onChanged: (val) => setState(() {
              _selectedGovernorate = val;
              _selectedWilayat = null;
            }),
            onClear: _selectedGovernorate != null
                ? () => setState(() {
                      _selectedGovernorate = null;
                      _selectedWilayat = null;
                    })
                : null,
          ),
          const SizedBox(height: 10),
          _buildDropdown(
            value: _selectedWilayat,
            hint: _selectedGovernorate == null
                ? 'Select Governorate First'
                : 'All Wilayats',
            icon: Icons.location_city_rounded,
            items: _wilayats,
            enabled: _selectedGovernorate != null,
            onChanged: _selectedGovernorate == null
                ? null
                : (val) => setState(() => _selectedWilayat = val),
            onClear: _selectedWilayat != null
                ? () => setState(() => _selectedWilayat = null)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: onClear != null && value != null
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close,
                      color: Colors.grey.shade500, size: 20))
              : Icon(Icons.keyboard_arrow_down_rounded,
                  color:
                      enabled ? Colors.grey.shade600 : Colors.grey.shade400),
          hint: Row(children: [
            Icon(icon,
                color: enabled
                    ? const Color(0xFF5C6BC0)
                    : Colors.grey.shade400,
                size: 20),
            const SizedBox(width: 8),
            Text(hint,
                style: TextStyle(
                    color: enabled
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ]),
          selectedItemBuilder: (context) => items
              .map((item) => Row(children: [
                    Icon(icon, color: const Color(0xFF5C6BC0), size: 20),
                    const SizedBox(width: 8),
                    Text(item,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                  ]))
              .toList(),
          items: enabled
              ? items
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList()
              : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActiveOrderBanner — shown when driver already has an active job
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveOrderBanner extends StatelessWidget {
  const _ActiveOrderBanner({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have an active order. Complete it before accepting another.',
              style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PickupButton — pending → picked
// ─────────────────────────────────────────────────────────────────────────────

class _PickupButton extends StatefulWidget {
  const _PickupButton({
    required this.orderId,
    required this.driverUid,
    required this.disabled,
    this.onNavigateToDeliveries,
  });
  final String orderId;
  final String driverUid;
  final bool disabled;
  final VoidCallback? onNavigateToDeliveries;

  @override
  State<_PickupButton> createState() => _PickupButtonState();
}

class _PickupButtonState extends State<_PickupButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.disabled) {
      return _disabledButton('Accept Pickup', Colors.blue.shade200);
    }
    return ElevatedButton.icon(
      onPressed: _loading ? null : _accept,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.shopping_bag_rounded, size: 16),
      label: const Text('Accept Pickup'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _accept() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: Colors.blue, size: 22),
            SizedBox(width: 10),
            Text('Accept Pickup?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to take this pickup?\n\n'
          'You will collect the dirty laundry from the customer and drop it off at the laundry shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      // Fetch driver's own profile for phone / name
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverUid)
          .get();
      final driverData = driverDoc.data() ?? {};
      final driverPhone = driverData['phone']    ?? '';
      final driverName  = driverData['fullName'] ?? '';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'driver_assigned',
        'pickupDriverId': widget.driverUid,
        'driverPhone':    driverPhone,
        'driverName':     driverName,
        'pickedUpAt': Timestamp.now(),
      });
      if (mounted) {
        _showSuccessSheet(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded,
                  color: Colors.blue.shade700, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Pickup Accepted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Head to the customer\'s address to collect the laundry.\nThen drop it off at the laundry shop.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNavigateToDeliveries?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to My Deliveries',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledButton(String label, Color color) {
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.lock_rounded, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeliveryButton — ready → out_for_delivery
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryButton extends StatefulWidget {
  const _DeliveryButton({
    required this.orderId,
    required this.driverUid,
    required this.disabled,
    this.onNavigateToDeliveries,
  });
  final String orderId;
  final String driverUid;
  final bool disabled;
  final VoidCallback? onNavigateToDeliveries;

  @override
  State<_DeliveryButton> createState() => _DeliveryButtonState();
}

class _DeliveryButtonState extends State<_DeliveryButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.disabled) {
      return _disabledButton('Accept Delivery', Colors.teal.shade200);
    }
    return ElevatedButton.icon(
      onPressed: _loading ? null : _accept,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.delivery_dining_rounded, size: 16),
      label: const Text('Accept Delivery'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _accept() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining_rounded, color: Colors.teal, size: 22),
            SizedBox(width: 10),
            Text('Accept Delivery?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to take this delivery?\n\n'
          'You will collect the clean laundry from the shop and deliver it to the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      // Fetch driver's own profile for phone / name
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverUid)
          .get();
      final driverData = driverDoc.data() ?? {};
      final driverPhone = driverData['phone']    ?? '';
      final driverName  = driverData['fullName'] ?? '';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'driver_heading_to_shop_delivery',
        'driverId':           widget.driverUid,
        'driverPhone':        driverPhone,
        'driverName':         driverName,
        'deliveryStartedAt':  Timestamp.now(),
      });
      if (mounted) {
        _showSuccessSheet(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.teal.shade50, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_rounded, color: Colors.teal, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Delivery Accepted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Collect the clean laundry from the shop and deliver it to the customer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNavigateToDeliveries?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to My Deliveries',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledButton(String label, Color color) {
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.lock_rounded, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionDropdown — collapsible section header + card list
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDropdown extends StatefulWidget {
  const _SectionDropdown({
    required this.label,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.count,
    required this.children,
  });
  final String       label;
  final IconData     icon;
  final Color        color;
  final String       subtitle;
  final int          count;
  final List<Widget> children;

  @override
  State<_SectionDropdown> createState() => _SectionDropdownState();
}

class _SectionDropdownState extends State<_SectionDropdown>
    with SingleTickerProviderStateMixin {
  bool _expanded = true; // open by default
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1, // starts expanded
    );
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tappable header ──────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.count}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: widget.color.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                // Animated chevron
                RotationTransition(
                  turns: _rotation,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: widget.color, size: 22),
                ),
              ],
            ),
          ),
        ),

        // ── Collapsible card list ────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              const SizedBox(height: 10),
              ...widget.children,
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

// ── Helper: amber locked banner (driver already has an active order) ─────────
Widget _lockedBanner() {
  return Builder(
    builder: (context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete your active order first.',
              style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}
