import '../../theme/user_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database.dart';
import 'user_cart_page.dart';

// ── Transport options ─────────────────────────────────────────────────────────
enum TransportOption { none, pickup, delivery, both }

class UserBookingPage extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> shopData;

  const UserBookingPage({
    super.key,
    required this.shopId,
    required this.shopData,
  });

  @override
  State<UserBookingPage> createState() => _UserBookingPageState();
}

class _UserBookingPageState extends State<UserBookingPage> {
  final _db = DatabaseService();

  // Map of serviceId → quantity (0 = not selected)
  final Map<String, int> _serviceQuantities = {};
  // Map of serviceId → unit price
  final Map<String, double> _servicePrices = {};
  // Map of serviceId → service name (needed for cart item)
  final Map<String, String> _serviceNames = {};

  bool _addingToCart = false;

  double get _servicesTotal {
    double total = 0;
    _serviceQuantities.forEach((id, qty) {
      total += qty * (_servicePrices[id] ?? 0.0);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.shopData['shopName'] ?? 'Laundry Shop';
    final wilayat = widget.shopData['wilayat'] ?? '';
    final governorate = widget.shopData['governorate'] ?? '';
    final location =
        [wilayat, governorate].where((s) => s.isNotEmpty).join(', ');
    final imageUrl = widget.shopData['shopImageUrl'] as String?;

    return Scaffold(
      backgroundColor: context.uiBackground,
      body: CustomScrollView(
        slivers: [
          // ── Hero banner ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: context.uiPrimary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: context.uiPrimary,
                        child: Icon(
                            Icons.store_mall_directory_outlined,
                            color: Colors.white24,
                            size: 80),
                      ),
                    )
                  else
                    Container(
                      color: context.uiPrimary,
                      child: Icon(Icons.store_mall_directory_outlined,
                          color: Colors.white24, size: 80),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, context.uiTextSecondary],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Shop header strip ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: context.uiSurface,
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.uiTextPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      if (location.isNotEmpty)
                        _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: location),
                      if ((widget.shopData['shopPhone'] ?? '').toString().isNotEmpty)
                        _InfoChip(
                            icon: Icons.phone_outlined,
                            label: widget.shopData['shopPhone'].toString()),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(height: 1, color: context.uiDivider),
                ],
              ),
            ),
          ),

          // ── Select Services ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Select Services',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.uiTextPrimary),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _ServicesList(
              stream: _db.getShopServicesStream(widget.shopId),
              quantities: _serviceQuantities,
              prices: _servicePrices,
              onToggle: (id, price, name) {
                setState(() {
                  if ((_serviceQuantities[id] ?? 0) > 0) {
                    _serviceQuantities[id] = 0;
                  } else {
                    _serviceQuantities[id] = 1;
                    _servicePrices[id] = price;
                    _serviceNames[id] = name;
                  }
                });
              },
              onQuantityChange: (id, delta) {
                setState(() {
                  final current = _serviceQuantities[id] ?? 0;
                  final next = (current + delta).clamp(0, 99);
                  _serviceQuantities[id] = next;
                });
              },
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Divider(height: 1, color: context.uiDivider),
            ),
          ),

          // ── Price Summary ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.uiFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Services Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.uiTextSecondary,
                      ),
                    ),
                    Text(
                      '${_servicesTotal.toStringAsFixed(3)} OMR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.uiPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Transport note ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.uiPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: context.uiPrimary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 16, color: context.uiPrimary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transport options can be selected in your cart.',
                        style: TextStyle(
                            fontSize: 12,
                            color: context.uiTextSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Add to Cart button ─────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _addingToCart ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.uiPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  context.uiPrimary.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _addingToCart
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Add to Cart logic ──────────────────────────────────────────────────────

  Future<void> _addToCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Require at least one service
    final selected = _serviceQuantities.entries
        .where((e) => e.value > 0)
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one service.'),
          backgroundColor: context.uiTextPrimary,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
      return;
    }

    setState(() => _addingToCart = true);
    try {
      // Check if cart has items from a DIFFERENT shop
      final cartSnap = await _db.getCartStream(uid).first;
      if (cartSnap.docs.isNotEmpty) {
        final existingShopId =
            (cartSnap.docs.first.data() as Map<String, dynamic>)['shopId']
                as String?;
        if (existingShopId != null && existingShopId != widget.shopId) {
          if (!mounted) return;
          final replace = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Replace Cart?',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              content: Text(
                  'Your cart contains items from another shop. Adding these items will clear your current cart.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Keep current',
                      style: TextStyle(color: context.uiTextSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Replace',
                      style: TextStyle(
                          color: context.uiPrimary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (replace != true) {
            setState(() => _addingToCart = false);
            return;
          }
          await _db.clearCart(uid);
        }
      }

      // Write to Firestore cart sub-collection
      final shopName =
          widget.shopData['shopName'] as String? ?? 'Laundry Shop';
      final shopImageUrl = widget.shopData['shopImageUrl'] as String?;
      final now = Timestamp.now();

      for (final entry in selected) {
        final serviceId = entry.key;
        final qty = entry.value;
        final price = _servicePrices[serviceId] ?? 0.0;
        final name = _serviceNames[serviceId] ?? 'Service';
        await _db.addToCart(uid, serviceId, {
          'shopId': widget.shopId,
          'shopName': shopName,
          if (shopImageUrl != null) 'shopImageUrl': shopImageUrl,
          'serviceId': serviceId,
          'serviceName': name,
          'unitPrice': price,
          'quantity': qty,
          'addedAt': now,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Added to cart!',
                      style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: context.uiPrimary,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              userPageRoute((_) => const UserCartPage()),
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }
}


// ── Services list ─────────────────────────────────────────────────────────────

class _ServicesList extends StatelessWidget {
  const _ServicesList({
    required this.stream,
    required this.quantities,
    required this.prices,
    required this.onToggle,
    required this.onQuantityChange,
  });

  final Stream<QuerySnapshot> stream;
  final Map<String, int> quantities;
  final Map<String, double> prices;
  final void Function(String id, double price, String name) onToggle;
  final void Function(String id, int delta) onQuantityChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(
                    color: context.uiPrimary)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.uiFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: context.uiTextHint),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Services will be added soon by the shop owner.',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.uiTextSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = d['name'] ?? 'Service';
            final unitPrice = (d['price'] as num?)?.toDouble() ?? 0.0;
            final qty = quantities[doc.id] ?? 0;
            final isChecked = qty > 0;
            final lineTotal = qty * unitPrice;

            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  // ── Checkbox ──
                  GestureDetector(
                    onTap: () => onToggle(doc.id, unitPrice, name as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? context.uiPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? context.uiPrimary
                              : context.uiTextHint,
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),

                  // ── Service name + price info ──
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onToggle(doc.id, unitPrice, name as String),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: context.uiTextPrimary,
                            ),
                          ),
                          Text(
                            '${unitPrice.toStringAsFixed(3)} OMR / item',
                            style: TextStyle(
                                fontSize: 11, color: context.uiTextHint),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Quantity counter (only if checked) ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: isChecked
                        ? Row(
                            children: [
                              // line total
                              Text(
                                '${lineTotal.toStringAsFixed(3)} OMR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.uiPrimary,
                                ),
                              ),
                              SizedBox(width: 10),
                              // minus
                              _QtyBtn(
                                icon: Icons.remove,
                                active: qty > 1,
                                onTap: () =>
                                    onQuantityChange(doc.id, -1),
                              ),
                              Container(
                                width: 30,
                                alignment: Alignment.center,
                                child: Text(
                                  '$qty',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.uiTextPrimary,
                                  ),
                                ),
                              ),
                              // plus
                              _QtyBtn(
                                icon: Icons.add,
                                active: true,
                                onTap: () =>
                                    onQuantityChange(doc.id, 1),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Transport radio group ──────────────────────────────────────────────────────

class _TransportRadioGroup extends StatelessWidget {
  const _TransportRadioGroup({
    required this.value,
    required this.onChanged,
  });

  final TransportOption value;
  final void Function(TransportOption) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TransportRadioTile(
          label: 'Pick up',
          subtitle: '0.500 OMR',
          option: TransportOption.pickup,
          groupValue: value,
          onChanged: onChanged,
        ),
        _TransportRadioTile(
          label: 'Delivery',
          subtitle: '0.500 OMR',
          option: TransportOption.delivery,
          groupValue: value,
          onChanged: onChanged,
        ),
        _TransportRadioTile(
          label: 'Pick up & Delivery',
          subtitle: '1.000 OMR',
          option: TransportOption.both,
          groupValue: value,
          onChanged: onChanged,
        ),
        _TransportRadioTile(
          label: 'None',
          subtitle: 'Drop off & collect yourself',
          option: TransportOption.none,
          groupValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TransportRadioTile extends StatelessWidget {
  const _TransportRadioTile({
    required this.label,
    required this.subtitle,
    required this.option,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final TransportOption option;
  final TransportOption groupValue;
  final void Function(TransportOption) onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = option == groupValue;
    return InkWell(
      onTap: () => onChanged(option),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: context.uiTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11, color: context.uiTextHint),
                  ),
                ],
              ),
            ),
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? context.uiPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? context.uiPrimary
                      : context.uiTextHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  const _QtyBtn(
      {required this.icon,
      required this.active,
      required this.onTap});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? context.uiPrimary
              : context.uiDivider,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon,
            size: 13,
            color: active ? Colors.white : context.uiTextHint),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.uiPrimary),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style:
                TextStyle(fontSize: 12, color: context.uiTextSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13, color: context.uiTextSecondary)),
        Text(
          '${value.toStringAsFixed(3)} OMR',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.uiTextPrimary),
        ),
      ],
    );
  }
}
