import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
import 'order_tracking_page.dart';
import 'payment_widgets.dart';

class PaymentPage extends StatefulWidget {
  final String shopId;
  final String shopName;
  final double totalPrice;
  final List<Map<String, dynamic>> items;

  const PaymentPage({
    Key? key,
    required this.shopId,
    required this.shopName,
    required this.totalPrice,
    required this.items,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // ── UI state ────────────────────────────────────────────────────────────────
  String _selectedMethod = 'card';
  bool _isProcessing = false;

  // ── Scheduling ──────────────────────────────────────────────────────────────
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // GlobalKey gives us access to CardPaymentFormState.validate()
  final _cardFormKey = GlobalKey<CardPaymentFormState>();

  // ── Time slot definitions ────────────────────────────────────────────────────
  static const _timeSlots = [
    {'title': 'Morning',   'time': '8:00 AM – 12:00 PM', 'icon': '🌅', 'startHour': 8,  'endHour': 12},
    {'title': 'Afternoon', 'time': '12:00 PM – 4:00 PM',  'icon': '☀️', 'startHour': 12, 'endHour': 16},
    {'title': 'Evening',   'time': '4:00 PM – 8:00 PM',  'icon': '🌆', 'startHour': 16, 'endHour': 20},
    {'title': 'Night',     'time': '8:00 PM – 12:00 AM', 'icon': '🌙', 'startHour': 20, 'endHour': 24},
  ];

  static const _months   = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  bool _isSlotDisabled(Map<String, dynamic> slot) {
    if (_selectedDate == null) return false;
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    if (selected != today) return false;
    final endHour = slot['endHour'] as int;
    if (endHour >= 24) return false; // Night slot never disabled for today
    return now.isAfter(DateTime(now.year, now.month, now.day, endHour));
  }

  String _generateOrderRef() {
    final now      = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix   = (10000 + Random().nextInt(90000)).toString();
    return '#DOB-$datePart-$suffix';
  }

  // ── Payment processing ───────────────────────────────────────────────────────

  Future<void> _processPayment() async {
    // Validate scheduling
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a pickup date and time slot.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Validate card form (if card selected)
    if (_selectedMethod == 'card') {
      if (!(_cardFormKey.currentState?.validate() ?? false)) return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('shopOwners').doc(widget.shopId).get(),
      ]);

      final customerData    = results[0].data() ?? {};
      final shopData        = results[1].data() ?? {};
      final customerName    = customerData['fullName']    ?? 'Customer';
      final customerPhone   = customerData['phone']       ?? '';
      final customerAddress = customerData['address']     ?? '';
      final customerGov     = customerData['governorate'] ?? '';
      final customerWilayat = customerData['wilayat']     ?? '';
      final customerLat     = (customerData['latitude']  as num?)?.toDouble();
      final customerLng     = (customerData['longitude'] as num?)?.toDouble();
      final shopGovernorate = shopData['governorate']     ?? '';
      final shopWilayat     = shopData['wilayat']         ?? '';
      final shopLat         = (shopData['latitude']  as num?)?.toDouble();
      final shopLng         = (shopData['longitude'] as num?)?.toDouble();
      final shopAddress     = shopData['shopAddress']     ?? '';
      final shopPhone       = shopData['phone']           ?? '';

      final slotData = _timeSlots.firstWhere((s) => s['title'] == _selectedTimeSlot);
      final scheduledDateFormatted =
          '${_weekdays[_selectedDate!.weekday - 1]}, ${_selectedDate!.day} '
          '${_months[_selectedDate!.month - 1]} · '
          '${slotData['title']} (${slotData['time']})';

      final orderRef = _generateOrderRef();

      // placeOrder returns a DocumentReference — capture its ID for tracking
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add({
        'userId':           uid,
        'shopId':           widget.shopId,
        'shopName':         widget.shopName,
        'shopGovernorate':  shopGovernorate,
        'shopWilayat':      shopWilayat,
        'shopAddress':      shopAddress,
        'shopLatitude':     shopLat,
        'shopLongitude':    shopLng,
        'items':            widget.items,
        'totalPrice':       widget.totalPrice,
        'scheduledDate':    scheduledDateFormatted,
        'status':           'order_placed',
        'paymentStatus':    'paid',
        'createdAt':        Timestamp.now(),
        'customerName':      customerName,
        'customerPhone':     customerPhone,
        'customerAddress':   customerAddress,
        'customerGov':       customerGov,
        'customerWilayat':   customerWilayat,
        'customerLatitude':  customerLat,
        'customerLongitude': customerLng,
        'shopPhone':         shopPhone,
        'orderRef':          orderRef,
      });
      final orderId = docRef.id;

      await DatabaseService().clearCart(uid);

      if (mounted) _showSuccessDialog(orderRef, scheduledDateFormatted, orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String orderRef, String scheduledDateFormatted, String orderId) {
    // Capture theme values from the PAGE's context before showDialog.
    // The dialog builder gets a different context (Navigator overlay)
    // that does NOT carry UserTheme, causing "No UserTheme found".
    final primary       = context.uiPrimary;
    final textSecondary = context.uiTextSecondary;
    final pageCtx       = context; // save page context for navigation after dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Order Confirmed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Your laundry pickup has been scheduled.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text('ORDER REFERENCE',
                      style: TextStyle(
                          fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700,
                          color: primary.withOpacity(0.7))),
                  const SizedBox(height: 4),
                  Text(orderRef,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: primary, letterSpacing: 1.2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.schedule, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(scheduledDateFormatted,
                  style: TextStyle(fontSize: 13, color: textSecondary))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.payments_rounded, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text('${widget.totalPrice.toStringAsFixed(3)} OMR',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: textSecondary)),
            ]),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop dialog, then replace the entire payment back-stack
                  // with OrderTrackingPage so back lands on UserMainPage/Orders.
                  Navigator.of(dialogCtx).pop();
                  Navigator.pushAndRemoveUntil(
                    pageCtx,
                    userPageRoute(
                      (_) => OrderTrackingPage(
                        orderId: orderId,
                        fromPayment: true,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Track My Order', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        title: Text('Checkout',
            style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: context.uiBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.uiTextPrimary),
      ),
      body: _isProcessing
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: context.uiPrimary),
                const SizedBox(height: 16),
                Text('Processing Payment...',
                    style: TextStyle(color: context.uiTextSecondary, fontSize: 16)),
              ]),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  OrderSummaryCard(
                    shopName:   widget.shopName,
                    items:      widget.items,
                    totalPrice: widget.totalPrice,
                  ),
                  const SizedBox(height: 24),

                  // Scheduling
                  Text('Pickup Scheduling',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
                  const SizedBox(height: 16),
                  _buildSchedulingSection(),
                  const SizedBox(height: 24),

                  // Payment method
                  Text('Payment Method',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
                  const SizedBox(height: 16),
                  PaymentMethodCard(
                    id: 'card', title: 'Credit / Debit Card',
                    icon: Icons.credit_card,
                    isSelected: _selectedMethod == 'card',
                    onTap: () => setState(() => _selectedMethod = 'card'),
                  ),
                  const SizedBox(height: 12),
                  PaymentMethodCard(
                    id: 'wallet', title: 'Pay with Cash',
                    icon: Icons.payments_rounded,
                    isSelected: _selectedMethod == 'wallet',
                    onTap: () => setState(() => _selectedMethod = 'wallet'),
                  ),
                  const SizedBox(height: 24),

                  // Card form or cash message
                  if (_selectedMethod == 'card')
                    CardPaymentForm(key: _cardFormKey)
                  else
                    const CashPaymentMessage(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: context.uiSurface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }

  // ── Scheduling section ───────────────────────────────────────────────────────

  Widget _buildSchedulingSection() {
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
          // Date picker
          Text('Pickup Date',
              style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: context.uiPrimary),
                  ),
                  child: child!,
                ),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  // Clear slot if it became disabled for the new date
                  if (_selectedTimeSlot != null) {
                    final slot = _timeSlots.firstWhere(
                      (s) => s['title'] == _selectedTimeSlot,
                      orElse: () => const {},
                    );
                    if (slot.isNotEmpty && _isSlotDisabled(slot)) {
                      _selectedTimeSlot = null;
                    }
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.uiBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: context.uiPrimary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null ? 'Select Date' : _formatDate(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null ? context.uiTextHint : context.uiTextPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Time slots
          Text('Time Slot',
              style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...(_timeSlots).map((slot) => TimeSlotTile(
                slot:       slot,
                isSelected: _selectedTimeSlot == slot['title'],
                isDisabled: _isSlotDisabled(slot),
                onTap:      () => setState(() => _selectedTimeSlot = slot['title'] as String),
              )),
        ],
      ),
    );
  }
}
