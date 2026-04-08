import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database.dart';

// ─── Service catalogue ────────────────────────────────────────────────────────
// Each entry maps a display name → its category key.
// Categories: 'cloth_cleaning' | 'blanket_cleaning'

class _ServiceOption {
  final String name;
  final String category;
  final String categoryLabel;
  const _ServiceOption(this.name, this.category, this.categoryLabel);
}

const _kServices = [
  // ── Cloth Cleaning ──────────────────────────────────────────────────────────
  _ServiceOption('Shirt Cleaning',          'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Trouser Cleaning',        'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Suit Dry Cleaning',       'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Dress Cleaning',          'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Jacket / Coat Cleaning',  'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Abaya / Dishdasha Cleaning', 'cloth_cleaning','Cloth Cleaning'),
  _ServiceOption('Sportswear Cleaning',     'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('School Uniform Cleaning', 'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('T-Shirt Cleaning',        'cloth_cleaning',   'Cloth Cleaning'),

  // ── Blanket Cleaning ────────────────────────────────────────────────────────
  _ServiceOption('Blanket Washing',         'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Bed Sheet Cleaning',      'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Duvet / Comforter Cleaning','blanket_cleaning','Blanket Cleaning'),
  _ServiceOption('Pillow Cover Washing',    'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Curtain Cleaning',        'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Carpet Cleaning',         'blanket_cleaning', 'Blanket Cleaning'),
];

// Category badge colours
const _kCategoryColor = {
  'cloth_cleaning':   Color(0xFF1A1AE6),
  'blanket_cleaning': Color(0xFF2C7A4B),
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class AddLaundryServicePage extends StatefulWidget {
  const AddLaundryServicePage({super.key});

  @override
  State<AddLaundryServicePage> createState() => _AddLaundryServicePageState();
}

class _AddLaundryServicePageState extends State<AddLaundryServicePage> {
  final _formKey    = GlobalKey<FormState>();
  final _priceCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _db         = DatabaseService();

  _ServiceOption? _selectedService;
  bool _saving = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await _db.addService(uid, {
        'name':          _selectedService!.name,
        'category':      _selectedService!.category,
        'categoryLabel': _selectedService!.categoryLabel,
        'price':         double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'description':   _descCtrl.text.trim(),
        'createdAt':     FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service added successfully!'),
            backgroundColor: Color(0xFF2C2C54),
          ),
        );
        setState(() => _selectedService = null);
        _priceCtrl.clear();
        _descCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _selectedService != null
        ? (_kCategoryColor[_selectedService!.category] ?? const Color(0xFF2C2C54))
        : Colors.transparent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Add Laundry Service',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C54),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick a service from the list. Customers will see it when browsing your shop.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 28),

                // ── Service dropdown ─────────────────────────────────────────
                _buildLabel('Service Name'),
                const SizedBox(height: 8),
                FormField<_ServiceOption>(
                  validator: (_) =>
                      _selectedService == null ? 'Please select a service' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(12),
                          border: field.hasError
                              ? Border.all(color: Colors.red, width: 1.5)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<_ServiceOption>(
                            value: _selectedService,
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Select a service…',
                                style: TextStyle(
                                    color: Colors.black38, fontSize: 14),
                              ),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            borderRadius: BorderRadius.circular(12),
                            items: _buildDropdownItems(),
                            onChanged: (val) =>
                                setState(() => _selectedService = val),
                          ),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Text(field.errorText!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),

                // ── Category badge (shown after selection) ───────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedService == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      categoryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedService!.category ==
                                              'cloth_cleaning'
                                          ? Icons.checkroom_outlined
                                          : Icons.bed_outlined,
                                      size: 13,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _selectedService!.categoryLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // ── Price ────────────────────────────────────────────────────
                _buildLabel('Price (OMR)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}')),
                  ],
                  decoration: _inputDecoration(
                    hint: '0.000',
                    prefixIcon: Icons.attach_money_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final p = double.tryParse(v.trim());
                    if (p == null || p < 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Description ──────────────────────────────────────────────
                _buildLabel('Description (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    hint: 'e.g. Includes washing, drying and folding...',
                    prefixIcon: Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Save button ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Add Service',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Group items by category with visual separators
  List<DropdownMenuItem<_ServiceOption>> _buildDropdownItems() {
    final items = <DropdownMenuItem<_ServiceOption>>[];
    String? lastCategory;

    for (final service in _kServices) {
      // Category header as a disabled item
      if (service.category != lastCategory) {
        lastCategory = service.category;
        final headerColor = _kCategoryColor[service.category] ??
            const Color(0xFF2C2C54);
        items.add(
          DropdownMenuItem<_ServiceOption>(
            enabled: false,
            value: null,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  Icon(
                    service.category == 'cloth_cleaning'
                        ? Icons.checkroom_outlined
                        : Icons.bed_outlined,
                    size: 14,
                    color: headerColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.categoryLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      items.add(
        DropdownMenuItem<_ServiceOption>(
          value: service,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              service.name,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 0.2,
        ),
      );

  InputDecoration _inputDecoration(
      {required String hint, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2C2C54), size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF2C2C54), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
