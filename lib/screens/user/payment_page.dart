import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
import 'user_main_page.dart'; // To navigate back

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
  String _selectedMethod = 'card'; // 'card' or 'wallet'
  bool _isProcessing = false;

  // Scheduling
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Form Controllers
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final List<Map<String, String>> _timeSlots = [
    {'title': 'Morning', 'time': '8:00 AM – 12:00 PM', 'icon': '🌅'},
    {'title': 'Afternoon', 'time': '12:00 PM – 4:00 PM', 'icon': '☀️'},
    {'title': 'Evening', 'time': '4:00 PM – 8:00 PM', 'icon': '🌆'},
  ];

  static const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String _formatDate(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  Future<void> _processPayment() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup date and time slot.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMethod == 'card') {
      if (_cardNumberCtrl.text.isEmpty ||
          _expiryCtrl.text.isEmpty ||
          _cvvCtrl.text.isEmpty ||
          _nameCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all card details.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch user's fullName + shop's location in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('shop_owners').doc(widget.shopId).get(),
      ]);
      final userDoc = results[0];
      final shopDoc = results[1];

      final customerName    = userDoc.data()?['fullName']    ?? 'Customer';
      final shopGovernorate = shopDoc.data()?['governorate'] ?? '';
      final shopWilayat     = shopDoc.data()?['wilayat']     ?? '';

      // Format scheduledDate: 'Monday, 28 Apr · Morning (8:00 AM – 12:00 PM)'
      final slotData = _timeSlots.firstWhere((s) => s['title'] == _selectedTimeSlot);
      final scheduledDateFormatted = '${_weekdays[_selectedDate!.weekday - 1]}, ${_selectedDate!.day} ${_months[_selectedDate!.month - 1]} · ${slotData['title']} (${slotData['time']})';

      // Create order
      await DatabaseService().placeOrder({
        'userId': uid,
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'shopGovernorate': shopGovernorate,
        'shopWilayat': shopWilayat,
        'items': widget.items,
        'totalPrice': widget.totalPrice,
        'scheduledDate': scheduledDateFormatted,
        'status': 'pending',
        'paymentStatus': 'paid',
        'createdAt': Timestamp.now(),
        'customerName': customerName,
      });

      // Clear the cart since the order is placed
      await DatabaseService().clearCart(uid);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Payment Successful! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Your order has been placed successfully.', style: TextStyle(fontSize: 16)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Navigate to UserMainPage
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const UserMainPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Track My Order'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: context.uiBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.uiTextPrimary),
      ),
      body: _isProcessing
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: context.uiPrimary),
                const SizedBox(height: 16),
                Text('Processing Payment...', style: TextStyle(color: context.uiTextSecondary, fontSize: 16)),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  
                  Text('Pickup Scheduling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
                  const SizedBox(height: 16),
                  _buildSchedulingSection(),
                  const SizedBox(height: 24),

                  Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
                  const SizedBox(height: 16),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  if (_selectedMethod == 'card') _buildCardForm() else _buildWalletMessage(),
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
                child: const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }

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
          // Date Picker
          Text('Pickup Date', style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: context.uiPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _selectedDate = date);
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

          // Time Slots
          Text('Time Slot', style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot['title'];
              return GestureDetector(
                onTap: () => setState(() => _selectedTimeSlot = slot['title']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? context.uiPrimary.withOpacity(0.1) : context.uiBackground,
                    border: Border.all(
                      color: isSelected ? context.uiPrimary : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(slot['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot['title']!,
                              style: TextStyle(
                                color: isSelected ? context.uiPrimary : context.uiTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot['time']!,
                              style: TextStyle(
                                color: context.uiTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: context.uiPrimary, size: 20)
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
          Row(
            children: [
              Icon(Icons.storefront, color: context.uiPrimary),
              const SizedBox(width: 8),
              Text(
                widget.shopName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.uiTextPrimary),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          ...widget.items.map((item) {
            final name = item['serviceName'];
            final qty = item['quantity'];
            final price = item['price'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$name x$qty', style: TextStyle(color: context.uiTextSecondary)),
                  Text('${(price * qty).toStringAsFixed(3)} OMR', style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
              Text('${widget.totalPrice.toStringAsFixed(3)} OMR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _buildMethodCard('card', 'Credit / Debit Card', Icons.credit_card),
        const SizedBox(height: 12),
        _buildMethodCard('wallet', 'Apple Pay / Google Pay', Icons.phone_iphone),
      ],
    );
  }

  Widget _buildMethodCard(String id, String title, IconData icon) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.uiSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? context.uiPrimary : context.uiDivider, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? context.uiPrimary : context.uiTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: context.uiTextPrimary)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: context.uiPrimary)
            else
              Icon(Icons.circle_outlined, color: context.uiDivider),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
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
          _buildTextField(_cardNumberCtrl, 'Card Number', 'XXXX XXXX XXXX XXXX', TextInputType.number),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_expiryCtrl, 'Expiry Date', 'MM/YY', TextInputType.datetime)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_cvvCtrl, 'CVV', '123', TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_nameCtrl, 'Cardholder Name', 'John Doe', TextInputType.name),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.uiTextHint),
            filled: true,
            fillColor: context.uiBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.uiDivider),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 64, color: context.uiPrimary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'You will be redirected to complete payment securely.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.uiTextSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
