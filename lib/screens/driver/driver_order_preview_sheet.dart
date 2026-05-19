import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderPreviewSheet — view-only order detail modal
// Call / WhatsApp buttons are disabled: the driver is just browsing.
// The actual accept button widget is injected from the caller so this file
// has no dependency on _PickupButton / _DeliveryButton.
// ─────────────────────────────────────────────────────────────────────────────

class OrderPreviewSheet {
  /// Open the bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> orderData,
    required bool isPickup,
    /// The ready-made accept button (or locked banner) to pin at the bottom.
    required Widget acceptButton,
    String? customTitle,
    IconData? customIcon,
    Color? customAccentColor,
    bool isShopOwner = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetContent(
        orderData:         orderData,
        isPickup:          isPickup,
        acceptButton:      acceptButton,
        customTitle:       customTitle,
        customIcon:        customIcon,
        customAccentColor: customAccentColor,
        isShopOwner:       isShopOwner,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SheetContent — the actual sheet UI
// ─────────────────────────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.orderData,
    required this.isPickup,
    required this.acceptButton,
    this.customTitle,
    this.customIcon,
    this.customAccentColor,
    this.isShopOwner = false,
  });

  final Map<String, dynamic> orderData;
  final bool isPickup;
  final Widget acceptButton;
  final String? customTitle;
  final IconData? customIcon;
  final Color? customAccentColor;
  final bool isShopOwner;

  String _formatTs(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final orderRef      = orderData['orderRef']      as String? ?? '—';
    final shopName      = orderData['shopName']      as String? ?? 'Unknown Shop';
    final customerName  = orderData['customerName']  as String? ?? 'Customer';
    final driverName    = orderData['driverName']    as String? ?? 'Driver';
    final scheduledDate = orderData['scheduledDate'] as String? ?? '—';
    final totalPrice    = (orderData['totalPrice']   as num?)?.toDouble() ?? 0.0;
    final createdAt     = orderData['createdAt'];
    final items         = (orderData['items'] as List<dynamic>?) ?? [];

    final customerAddr = [
      orderData['customerAddress'],
      orderData['customerWilayat'],
      orderData['customerGov'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(', ');

    final shopAddr = [
      orderData['shopAddress'],
      orderData['shopWilayat'],
      orderData['shopGovernorate'],
    ].where((s) => s != null && s.toString().isNotEmpty).join(', ');

    final accentColor = customAccentColor ?? (isPickup ? Colors.blue.shade700 : Colors.teal.shade700);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => GestureDetector(
          onTap: () {}, // Prevent taps inside the container from closing it
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
            // ── Drag handle ──────────────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Header bar ───────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    customIcon ?? (isPickup
                        ? Icons.shopping_bag_rounded
                        : Icons.delivery_dining_rounded),
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customTitle ?? (isPickup ? 'Pickup Order Preview' : 'Delivery Order Preview'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Order ref chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            orderRef,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer + Shop chips
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          icon: Icons.person_outline_rounded,
                          label: 'Customer',
                          value: customerName,
                          accent: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoBlock(
                          icon: Icons.storefront_rounded,
                          label: 'Laundry Shop',
                          value: shopName,
                          accent: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!isShopOwner) ...[
                    // Locations
                    _sectionTitle('Locations', accentColor),
                    const SizedBox(height: 10),
                    _LocationCard(
                      label: "📍 Customer's Address",
                      address: customerAddr,
                      accentColor: Colors.blue.shade700,
                      isCurrentLeg: isPickup,
                    ),
                    const SizedBox(height: 8),
                    _LocationCard(
                      label: '🏪 Laundry Shop',
                      address: shopAddr,
                      accentColor: Colors.teal,
                      isCurrentLeg: !isPickup,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact
                  _sectionTitle('Contact', accentColor),
                  const SizedBox(height: 10),
                  if (isShopOwner) ...[
                    if (orderData['driverPhone'] != null)
                      _ContactRow(
                        icon: Icons.directions_car_rounded,
                        label: driverName,
                        subtitle: 'Driver',
                        phone: orderData['driverPhone'],
                      ),
                  ] else ...[
                    _DisabledContactRow(
                      icon: Icons.storefront_rounded,
                      label: shopName,
                      subtitle: 'Laundry Shop',
                    ),
                  ],
                  if (!isShopOwner || (isShopOwner && orderData['driverPhone'] != null))
                    const SizedBox(height: 8),
                  if (isShopOwner) ...[
                    _ContactRow(
                      icon: Icons.person_outline_rounded,
                      label: customerName,
                      subtitle: 'Customer',
                      phone: orderData['customerPhone'],
                    ),
                  ] else ...[
                    _DisabledContactRow(
                      icon: Icons.person_outline_rounded,
                      label: customerName,
                      subtitle: 'Customer',
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Order details
                  _sectionTitle('Order Details', accentColor),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Scheduled',
                    value: scheduledDate,
                  ),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Placed',
                    value: _formatTs(createdAt),
                  ),
                  _DetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Total',
                    value: 'OMR ${totalPrice.toStringAsFixed(3)}',
                    valueColor: Colors.green.shade700,
                    bold: true,
                  ),

                  // Items
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Items', accentColor),
                    const SizedBox(height: 8),
                    _ItemsCard(items: items, accentColor: accentColor),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ── Pinned accept button ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: acceptButton,
            ),
          ],
        ),
      ),
    )));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (all private — only used inside this file)
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionTitle(String title, Color accent) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.label,
    required this.address,
    required this.accentColor,
    required this.isCurrentLeg,
  });
  final String label;
  final String address;
  final Color accentColor;
  final bool isCurrentLeg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentLeg
            ? accentColor.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentLeg
              ? accentColor.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: isCurrentLeg
                            ? accentColor
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (isCurrentLeg) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'CURRENT STOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.isNotEmpty ? address : 'Address not available',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Navigate icon — greyed out (preview mode)
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.navigation_rounded,
                color: Colors.grey.shade400, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DisabledContactRow extends StatelessWidget {
  const _DisabledContactRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Call — disabled
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.phone_rounded,
                color: Colors.grey.shade400, size: 18),
          ),
          // WhatsApp — disabled
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.phone,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final String? phone;

  Future<void> _call() async {
    if (phone == null || phone!.isEmpty) return;
    final cleanPhone = phone!.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    if (phone == null || phone!.isEmpty) return;
    final cleanPhone = phone!.replaceAll(RegExp(r'\D'), '');
    final number = cleanPhone.startsWith('968') ? cleanPhone : '968$cleanPhone';
    final uri = Uri.parse('https://wa.me/$number');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueGrey.shade600, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            // Call
            InkWell(
              onTap: _call,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.phone_rounded,
                    color: Colors.green.shade600, size: 18),
              ),
            ),
            // WhatsApp
            InkWell(
              onTap: _whatsapp,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'W',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.accentColor});
  final List<dynamic> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item   = e.value as Map<String, dynamic>;
          final isLast = e.key == items.length - 1;
          final name   = item['name'] ?? item['serviceName'] ?? 'Item';
          final qty    = item['quantity'] ?? 1;
          final price  = (item['price'] ?? 0.0).toDouble();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$name × $qty',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                    Text(
                      'OMR ${price.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }
}
