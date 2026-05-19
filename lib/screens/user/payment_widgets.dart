import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/user_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card validators (pure functions, no state)
// ─────────────────────────────────────────────────────────────────────────────

String? validateCardNumber(String raw) {
  final digits = raw.replaceAll(' ', '');
  if (digits.isEmpty) return 'Card number is required';
  if (digits.length < 16) return 'Enter a valid 16-digit card number';
  return null;
}

String? validateExpiry(String value) {
  if (value.isEmpty) return 'Expiry date is required';
  // Strip any non-digit characters except '/' for clean parsing
  final parts = value.split('/');
  if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
    return 'Use MM/YY format';
  }
  final month = int.tryParse(parts[0]);
  final year  = int.tryParse(parts[1]);
  if (month == null || year == null) return 'Invalid date';
  if (month < 1 || month > 12)       return 'Month must be 01–12';
  final now       = DateTime.now();
  final fullYear  = 2000 + year;
  // Cap: cards don't expire more than 10 years in the future
  if (fullYear > now.year + 10)      return 'Invalid expiry year';
  final expiryDate = DateTime(fullYear, month + 1);
  if (expiryDate.isBefore(now))      return 'Card has expired';
  return null;
}

String? validateCvv(String value) {
  if (value.isEmpty)    return 'CVV is required';
  if (value.length < 3) return 'CVV must be 3–4 digits';
  return null;
}

String? validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty)  return 'Cardholder name is required';
  if (trimmed.length < 2) return 'Name is too short';
  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmed)) {
    return 'Name must contain only letters';
  }
  return null;
}

String? detectCardBrand(String digits) {
  if (digits.startsWith('4')) return 'visa';
  final prefix = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
  if (prefix != null && prefix >= 51 && prefix <= 55) return 'mastercard';
  final prefix6 = digits.length >= 6 ? int.tryParse(digits.substring(0, 6)) : null;
  if (prefix6 != null && prefix6 >= 222100 && prefix6 <= 272099) return 'mastercard';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// CardPaymentForm — StatefulWidget with a public validate() method via GlobalKey
// ─────────────────────────────────────────────────────────────────────────────

class CardPaymentForm extends StatefulWidget {
  const CardPaymentForm({super.key});

  @override
  State<CardPaymentForm> createState() => CardPaymentFormState();
}

class CardPaymentFormState extends State<CardPaymentForm> {
  final cardNumberCtrl = TextEditingController();
  final expiryCtrl     = TextEditingController();
  final cvvCtrl        = TextEditingController();
  final nameCtrl       = TextEditingController();

  String? _cardNumberError;
  String? _expiryError;
  String? _cvvError;
  String? _nameError;

  final _touched = {'card': false, 'expiry': false, 'cvv': false, 'name': false};

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  /// Call from parent on submit. Returns true if all fields are valid.
  bool validate() {
    final cardErr   = validateCardNumber(cardNumberCtrl.text);
    final expiryErr = validateExpiry(expiryCtrl.text);
    final cvvErr    = validateCvv(cvvCtrl.text);
    final nameErr   = validateName(nameCtrl.text);
    setState(() {
      _cardNumberError = cardErr;
      _expiryError     = expiryErr;
      _cvvError        = cvvErr;
      _nameError       = nameErr;
      _touched.updateAll((_, __) => true);
    });
    return cardErr == null && expiryErr == null && cvvErr == null && nameErr == null;
  }

  @override
  Widget build(BuildContext context) {
    final digits = cardNumberCtrl.text.replaceAll(' ', '');
    final brand  = detectCardBrand(digits);

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
          // ── Card Number ────────────────────────────────────────────────────
          _CardField(
            controller: cardNumberCtrl,
            label: 'Card Number',
            hint: 'XXXX XXXX XXXX XXXX',
            keyboardType: TextInputType.number,
            // digits-only: formatter blocks letters at the OS level
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 19,
            error: _cardNumberError,
            suffix: brand == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      brand == 'visa' ? 'VISA' : 'MC',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                        color: brand == 'visa'
                            ? const Color(0xFF1A1F71)
                            : const Color(0xFFEB001B),
                      ),
                    ),
                  ),
            onChanged: (raw) {
              // Auto-format to groups of 4
              final d = raw.replaceAll(' ', '');
              final buf = StringBuffer();
              for (int i = 0; i < d.length && i < 16; i++) {
                if (i > 0 && i % 4 == 0) buf.write(' ');
                buf.write(d[i]);
              }
              final fmt = buf.toString();
              if (fmt != raw) {
                cardNumberCtrl.value = TextEditingValue(
                  text: fmt,
                  selection: TextSelection.collapsed(offset: fmt.length),
                );
              }
              if (_touched['card']!) {
                setState(() => _cardNumberError = validateCardNumber(fmt));
              }
            },
            onTap: () => setState(() => _touched['card'] = true),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Expiry ──────────────────────────────────────────────────────
              Expanded(
                child: _CardField(
                  controller: expiryCtrl,
                  label: 'Expiry Date',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  error: _expiryError,
                  onChanged: (raw) {
                    // Strip non-digits then auto-insert slash
                    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length > 4) digits = digits.substring(0, 4);
                    String fmt = digits.length > 2
                        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
                        : digits;
                    if (fmt != raw) {
                      expiryCtrl.value = TextEditingValue(
                        text: fmt,
                        selection: TextSelection.collapsed(offset: fmt.length),
                      );
                    }
                    if (_touched['expiry']!) {
                      setState(() => _expiryError = validateExpiry(fmt));
                    }
                  },
                  onTap: () => setState(() => _touched['expiry'] = true),
                ),
              ),
              const SizedBox(width: 16),
              // ── CVV ─────────────────────────────────────────────────────────
              Expanded(
                child: _CardField(
                  controller: cvvCtrl,
                  label: 'CVV',
                  hint: '•••',
                  keyboardType: TextInputType.number,
                  // digits-only: prevents any letters/symbols
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  obscureText: true,
                  error: _cvvError,
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.lock_outline, size: 18, color: context.uiTextHint),
                  ),
                  onChanged: (v) {
                    if (_touched['cvv']!) {
                      setState(() => _cvvError = validateCvv(v));
                    }
                  },
                  onTap: () => setState(() => _touched['cvv'] = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Cardholder Name ─────────────────────────────────────────────────
          _CardField(
            controller: nameCtrl,
            label: 'Cardholder Name',
            hint: 'John Doe',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            // letters and spaces only
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
            error: _nameError,
            onChanged: (v) {
              if (_touched['name']!) {
                setState(() => _nameError = validateName(v));
              }
            },
            onTap: () => setState(() => _touched['name'] = true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardField — private reusable input widget
// ─────────────────────────────────────────────────────────────────────────────

class _CardField extends StatelessWidget {
  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.obscureText = false,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
    this.error,
    this.onChanged,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final String? error;
  final void Function(String)? onChanged;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.redAccent : context.uiTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          style: TextStyle(fontSize: 15, color: context.uiTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.uiTextHint),
            filled: true,
            fillColor: hasError
                ? Colors.redAccent.withOpacity(0.05)
                : context.uiBackground,
            counterText: '',
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : context.uiPrimary,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: Colors.redAccent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  error!,
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OrderSummaryCard
// ─────────────────────────────────────────────────────────────────────────────

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.shopName,
    required this.items,
    required this.totalPrice,
  });

  final String shopName;
  final List<Map<String, dynamic>> items;
  final double totalPrice;

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
          Row(
            children: [
              Icon(Icons.storefront, color: context.uiPrimary),
              const SizedBox(width: 8),
              Text(
                shopName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.uiTextPrimary),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          ...items.map((item) {
            final name  = item['serviceName'];
            final qty   = item['quantity'];
            final price = item['price'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$name x$qty', style: TextStyle(color: context.uiTextSecondary)),
                  Text('${(price * qty).toStringAsFixed(3)} OMR',
                      style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transport', style: TextStyle(color: context.uiTextSecondary)),
              Text('1.000 OMR', style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.uiTextPrimary)),
              Text('${totalPrice.toStringAsFixed(3)} OMR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.uiPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentMethodCard
// ─────────────────────────────────────────────────────────────────────────────

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.uiSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.uiPrimary : context.uiDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? context.uiPrimary : context.uiTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: context.uiTextPrimary,
                ),
              ),
            ),
            isSelected
                ? Icon(Icons.check_circle, color: context.uiPrimary)
                : Icon(Icons.circle_outlined, color: context.uiDivider),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CashPaymentMessage
// ─────────────────────────────────────────────────────────────────────────────

class CashPaymentMessage extends StatelessWidget {
  const CashPaymentMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.uiSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.uiDivider),
      ),
      child: Column(
        children: [
          Icon(Icons.payments_rounded, size: 64, color: context.uiPrimary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Pay with Cash',
              style: TextStyle(color: context.uiTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Hand the payment to the driver upon pickup. No online transaction required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.uiTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TimeSlotTile
// ─────────────────────────────────────────────────────────────────────────────

class TimeSlotTile extends StatelessWidget {
  const TimeSlotTile({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final Map<String, dynamic> slot;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? context.uiPrimary.withOpacity(0.1) : context.uiBackground,
            border: Border.all(
              color: isDisabled
                  ? context.uiDivider
                  : isSelected
                      ? context.uiPrimary
                      : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(slot['icon'] as String, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          slot['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDisabled
                                ? context.uiTextSecondary
                                : isSelected
                                    ? context.uiPrimary
                                    : context.uiTextPrimary,
                          ),
                        ),
                        if (isDisabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Unavailable',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.uiTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(slot['time'] as String,
                        style: TextStyle(color: context.uiTextSecondary, fontSize: 13)),
                  ],
                ),
              ),
              if (isSelected && !isDisabled)
                Icon(Icons.check_circle, color: context.uiPrimary, size: 20)
              else if (isDisabled)
                Icon(Icons.block, color: context.uiTextSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
