import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
import 'user_booking_page.dart';
import 'payment_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
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

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Cancel Request',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: context.uiTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this request? All selected services will be removed from your cart and this action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: context.uiTextSecondary,
            height: 1.55,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.uiTextSecondary,
              side: BorderSide(color: context.uiDivider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Keep Request',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Yes, Cancel',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || _uid == null) return;
    setState(() => _clearing = true);
    try {
      await _db.clearCart(_uid!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your request has been cancelled successfully.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: context.uiTextPrimary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _proceedToPayment(List<QueryDocumentSnapshot> docs, double grandTotal) {
    if (docs.isEmpty) return;

    final firstData = docs.first.data() as Map<String, dynamic>;
    final shopId = firstData['shopId'] as String? ?? '';
    final shopName = firstData['shopName'] as String? ?? 'Laundry Shop';

    final items = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final qty = (data['quantity'] as num?)?.toInt() ?? 1;
      final price = (data['unitPrice'] as num?)?.toDouble() ?? 0.0;
      return {
        'serviceName': data['serviceName'] ?? 'Service',
        'quantity': qty,
        'price': price,
      };
    }).toList();

    Navigator.push(
      context,
      userPageRoute((_) => PaymentPage(
        shopId: shopId,
        shopName: shopName,
        totalPrice: grandTotal,
        items: items,
      )),
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
          backgroundColor: context.uiBackground,
          appBar: _buildAppBar(hasItems: docs.isNotEmpty),
          body: isLoading
              ? Center(
                child: CircularProgressIndicator(color: context.uiPrimary))
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
      backgroundColor: context.uiBackground,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.uiFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: context.uiTextPrimary),
        ),
      ),
      title: Text(
        'My Cart',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.uiTextPrimary),
      ),
      actions: [
        if (hasItems)
          _clearing
              ? Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent)),
                )
              : IconButton(
                  tooltip: 'Clear cart',
                  icon: Icon(Icons.delete_sweep_outlined,
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
        padding: EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: context.uiPrimary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined,
                  size: 52, color: context.uiPrimary),
            ),
            SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.uiTextPrimary),
            ),
            SizedBox(height: 10),
            Text(
              'Browse laundry shops and add services to your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.uiTextSecondary, height: 1.5),
            ),
            SizedBox(height: 28),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Browse Shops',
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
    final grandTotal = subtotal + 1.000;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      children: [
        // ── Shop header ──────────────────────────────────────────────────────
        _buildShopHeader(shopName, shopImageUrl, docs.length),

        SizedBox(height: 4),

        // ── Item rows ────────────────────────────────────────────────────────
        ...docs.map((doc) => _buildItemRow(doc)),

        // ── Add Another Service ──────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final shopId = firstData['shopId'] as String?;
                if (shopId != null) {
                  Navigator.push(
                    context,
                    userPageRoute((_) => UserBookingPage(
                      shopId: shopId,
                      shopData: {
                        'shopName': shopName,
                        if (shopImageUrl != null) 'shopImageUrl': shopImageUrl,
                      },
                    )),
                  );
                }
              },
              icon: Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                'Add another service',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: context.uiPrimary,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                backgroundColor: context.uiPrimary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        const _SectionDivider(),


        // ── Order Summary ────────────────────────────────────────────────────
        const _SectionHeader(title: 'Order Summary'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.uiFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryLine(
                    label: 'Subtotal (${docs.length} item${docs.length == 1 ? '' : 's'})',
                    value: subtotal),
                SizedBox(height: 8),
                _SummaryLine(label: 'Transport', value: 1.000),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: context.uiDivider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.uiTextPrimary)),
                    Text(
                      '${grandTotal.toStringAsFixed(3)} OMR',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.uiPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 110), // space for bottom bar
      ],
    );
  }

  Widget _buildShopHeader(
      String shopName, String? imageUrl, int itemCount) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.uiPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: context.uiPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Shop avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: context.uiPrimary.withValues(alpha: 0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? Image.network(imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.store_mall_directory_outlined,
                        color: context.uiPrimary,
                        size: 26))
                : Icon(Icons.store_mall_directory_outlined,
                    color: context.uiPrimary, size: 26),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.uiTextPrimary)),
                SizedBox(height: 2),
                Text(
                  '$itemCount service${itemCount == 1 ? '' : 's'} selected',
                  style: TextStyle(
                      fontSize: 12, color: context.uiTextSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_outlined,
              size: 18, color: context.uiPrimary),
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
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.uiDivider),
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
              color: context.uiPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.dry_cleaning_outlined,
                color: context.uiPrimary, size: 20),
          ),
          SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.uiTextPrimary)),
                Text('${unitPrice.toStringAsFixed(3)} OMR / item',
                    style: TextStyle(
                        fontSize: 11, color: context.uiTextHint)),
              ],
            ),
          ),

          // Qty controls
          Row(
            children: [
              // Line total
              Text(
                '${lineTotal.toStringAsFixed(3)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.uiPrimary),
              ),
              SizedBox(width: 8),
              _CartQtyBtn(
                icon: qty > 1 ? Icons.remove : Icons.delete_outline,
                color: qty > 1
                    ? context.uiPrimary
                    : Colors.redAccent,
                onTap: () => _updateQty(doc.id, qty - 1),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('$qty',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.uiTextPrimary)),
              ),
              _CartQtyBtn(
                icon: Icons.add,
                color: context.uiPrimary,
                onTap: () => _updateQty(doc.id, qty + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBottomBar(List<QueryDocumentSnapshot> docs) {
    final grandTotal = _subtotal(docs) + 1.000;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: context.uiBackground,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => _proceedToPayment(docs, grandTotal),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.uiPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Proceed to Payment  ·  ${grandTotal.toStringAsFixed(3)} OMR',
                style: TextStyle(
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
      padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.uiTextPrimary)),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Divider(height: 1, color: context.uiDivider),
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
            style: TextStyle(fontSize: 13, color: context.uiTextSecondary)),
        Text('${value.toStringAsFixed(3)} OMR',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.uiTextPrimary)),
      ],
    );
  }
}
