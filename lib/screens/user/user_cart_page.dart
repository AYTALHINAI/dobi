import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import 'user_booking_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Transport Option (mirrors booking page)
// ─────────────────────────────────────────────────────────────────────────────
enum _Transport { none, pickup, delivery, both }

extension _TransportExt on _Transport {
  String get label {
    switch (this) {
      case _Transport.pickup:
        return 'Pick up';
      case _Transport.delivery:
        return 'Delivery';
      case _Transport.both:
        return 'Pick up & Delivery';
      case _Transport.none:
        return 'None (self drop-off)';
    }
  }

  String get subtitle {
    switch (this) {
      case _Transport.pickup:
      case _Transport.delivery:
        return '0.500 OMR';
      case _Transport.both:
        return '1.000 OMR';
      case _Transport.none:
        return 'No transport cost';
    }
  }

  double get fee {
    switch (this) {
      case _Transport.pickup:
      case _Transport.delivery:
        return 0.500;
      case _Transport.both:
        return 1.000;
      case _Transport.none:
        return 0.0;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Page
// ─────────────────────────────────────────────────────────────────────────────

class UserCartPage extends StatefulWidget {
  const UserCartPage({super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final _db = DatabaseService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  _Transport _transport = _Transport.none;
  bool _clearing = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _subtotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, d) {
      final data = d.data() as Map<String, dynamic>;
      final price = (data['unitPrice'] as num?)?.toDouble() ?? 0.0;
      final qty = (data['quantity'] as num?)?.toInt() ?? 1;
      return sum + price * qty;
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _updateQty(String cartItemId, int newQty) async {
    final uid = _uid;
    if (uid == null) return;
    if (newQty <= 0) {
      await _db.removeCartItem(uid, cartItemId);
    } else {
      await _db.updateCartItemQty(uid, cartItemId, newQty);
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.removeCartItem(uid, cartItemId);
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || _uid == null) return;
    setState(() => _clearing = true);
    try {
      await _db.clearCart(_uid!);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _proceedToPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payment coming soon! We\'re working on it.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF1A1AE6),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return Scaffold(
        appBar: _buildAppBar(hasItems: false),
        body: const Center(child: Text('Not signed in.')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db.getCartStream(uid),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(hasItems: docs.isNotEmpty),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A1AE6)))
              : docs.isEmpty
                  ? _buildEmptyState()
                  : _buildCartContent(docs),
          bottomNavigationBar: docs.isEmpty
              ? null
              : _buildBottomBar(docs),
        );
      },
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar({required bool hasItems}) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.black87),
        ),
      ),
      title: const Text(
        'My Cart',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87),
      ),
      actions: [
        if (hasItems)
          _clearing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent)),
                )
              : IconButton(
                  tooltip: 'Clear cart',
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                  onPressed: _confirmClearCart,
                ),
      ],
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1AE6).withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 52, color: Color(0xFF1A1AE6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              'Browse laundry shops and add services to your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1AE6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Browse Shops',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cart Content ────────────────────────────────────────────────────────────

  Widget _buildCartContent(List<QueryDocumentSnapshot> docs) {
    // Derive shop info from the first item (all items share one shop)
    final firstData = docs.first.data() as Map<String, dynamic>;
    final shopName = firstData['shopName'] as String? ?? 'Laundry Shop';
    final shopImageUrl = firstData['shopImageUrl'] as String?;
    final subtotal = _subtotal(docs);
    final grandTotal = subtotal + _transport.fee;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      children: [
        // ── Shop header ──────────────────────────────────────────────────────
        _buildShopHeader(shopName, shopImageUrl, docs.length),

        const SizedBox(height: 4),

        // ── Item rows ────────────────────────────────────────────────────────
        ...docs.map((doc) => _buildItemRow(doc)),

        // ── Add Another Service ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final shopId = firstData['shopId'] as String?;
                if (shopId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserBookingPage(
                        shopId: shopId,
                        shopData: {
                          'shopName': shopName,
                          if (shopImageUrl != null) 'shopImageUrl': shopImageUrl,
                        },
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                'Add another service',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1AE6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                backgroundColor: const Color(0xFF1A1AE6).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        const _SectionDivider(),

        // ── Transport ────────────────────────────────────────────────────────
        const _SectionHeader(title: 'Transport'),
        ..._Transport.values.map((t) => _buildTransportTile(t)),

        const _SectionDivider(),

        // ── Order Summary ────────────────────────────────────────────────────
        const _SectionHeader(title: 'Order Summary'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryLine(
                    label: 'Subtotal (${docs.length} item${docs.length == 1 ? '' : 's'})',
                    value: subtotal),
                const SizedBox(height: 8),
                _SummaryLine(label: 'Transport', value: _transport.fee),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFDDDDDD)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    Text(
                      '${grandTotal.toStringAsFixed(3)} OMR',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1AE6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Coming soon notice ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Online payment is coming soon. Stay tuned!',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 110), // space for bottom bar
      ],
    );
  }

  Widget _buildShopHeader(
      String shopName, String? imageUrl, int itemCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1AE6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF1A1AE6).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Shop avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF1A1AE6).withValues(alpha: 0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_mall_directory_outlined,
                        color: Color(0xFF1A1AE6),
                        size: 26))
                : const Icon(Icons.store_mall_directory_outlined,
                    color: Color(0xFF1A1AE6), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(
                  '$itemCount service${itemCount == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_outlined,
              size: 18, color: Color(0xFF1A1AE6)),
        ],
      ),
    );
  }

  Widget _buildItemRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['serviceName'] as String? ?? 'Service';
    final unitPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final qty = (data['quantity'] as num?)?.toInt() ?? 1;
    final lineTotal = unitPrice * qty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1AE6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dry_cleaning_outlined,
                color: Color(0xFF1A1AE6), size: 20),
          ),
          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text('${unitPrice.toStringAsFixed(3)} OMR / item',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),

          // Qty controls
          Row(
            children: [
              // Line total
              Text(
                '${lineTotal.toStringAsFixed(3)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1AE6)),
              ),
              const SizedBox(width: 8),
              _CartQtyBtn(
                icon: qty > 1 ? Icons.remove : Icons.delete_outline,
                color: qty > 1
                    ? const Color(0xFF1A1AE6)
                    : Colors.redAccent,
                onTap: () => _updateQty(doc.id, qty - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$qty',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              _CartQtyBtn(
                icon: Icons.add,
                color: const Color(0xFF1A1AE6),
                onTap: () => _updateQty(doc.id, qty + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportTile(_Transport option) {
    final isSelected = option == _transport;
    return InkWell(
      onTap: () => setState(() => _transport = option),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(option.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF1A1AE6)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1A1AE6)
                      : Colors.black26,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle,
                      size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<QueryDocumentSnapshot> docs) {
    final grandTotal = _subtotal(docs) + _transport.fee;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1AE6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Proceed to Payment  ·  ${grandTotal.toStringAsFixed(3)} OMR',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CartQtyBtn extends StatelessWidget {
  const _CartQtyBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87)),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text('${value.toStringAsFixed(3)} OMR',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}
