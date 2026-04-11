import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../database.dart';

class ShopOwnerServicesPage extends StatefulWidget {
  const ShopOwnerServicesPage({super.key});

  @override
  State<ShopOwnerServicesPage> createState() => _ShopOwnerServicesPageState();
}

class _ShopOwnerServicesPageState extends State<ShopOwnerServicesPage> {
  // ── Shop info ──────────────────────────────────────────────────────────────
  String _shopName = '';
  String _wilayat = '';
  String _governorate = '';
  String? _shopImageUrl;
  bool _loadingInfo = true;
  bool _uploadingPhoto = false;
  final _db = DatabaseService();

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  Future<void> _loadShopInfo() async {
    if (_uid == null) return;
    try {
      final doc = await _db.getShopOwnerDoc(_uid!);
      if (doc.exists && mounted) {
        final data = doc.data()! as Map<String, dynamic>;
        setState(() {
          _shopName = data['shopName'] ?? '';
          _wilayat = data['wilayat'] ?? '';
          _governorate = data['governorate'] ?? '';
          // Use shopImageUrl first; fall back to profileImageUrl so both pages share the same photo
          _shopImageUrl = (data['shopImageUrl'] as String?)
              ?? (data['profileImageUrl'] as String?);
          _loadingInfo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  // ── Photo upload ───────────────────────────────────────────────────────────
  Future<void> _pickAndUploadShopPhoto() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || _uid == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('shopOwners/$_uid/shop_cover.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _db.updateShopCoverPhoto(_uid!, url);

      if (mounted) setState(() => _shopImageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deleteShopPhoto() async {
    if (_uid == null) return;
    // Confirm before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove the shop photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Delete from Storage
      await FirebaseStorage.instance
          .ref()
          .child('shopOwners/$_uid/shop_cover.jpg')
          .delete();
    } catch (_) {
      // Storage file might not exist — that's fine
    }
    try {
      await _db.deleteShopPhoto(_uid!);
      if (mounted) setState(() => _shopImageUrl = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2C2C54)),
              title: const Text('Change Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadShopPhoto();
              },
            ),
            if (_shopImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteShopPhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── App bar with shop photo banner ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF2C2C54),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image or placeholder
                    _shopImageUrl != null
                        ? Image.network(
                            _shopImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : _buildBannerPlaceholder(),
                            errorBuilder: (_, __, ___) =>
                                _buildBannerPlaceholder(),
                          )
                        : _buildBannerPlaceholder(),

                    // Dark gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),

                    // Upload overlay / spinner
                    if (_uploadingPhoto)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        ),
                      ),

                    // Camera badge (bottom-right)
                    if (!_uploadingPhoto)
                      Positioned(
                        bottom: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt,
                                  color: Colors.white, size: 15),
                              SizedBox(width: 5),
                              Text('Change Photo',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Shop info header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: _loadingInfo
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shopName.isEmpty ? 'My Laundry Shop' : _shopName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: Color(0xFF2C2C54)),
                            const SizedBox(width: 4),
                            Text(
                              [_wilayat, _governorate]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Select Services',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // ── Services list from Firestore ────────────────────────────────────
          if (_uid != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: _db.getShopServicesStream(_uid!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.local_laundry_service_outlined,
                                  size: 52, color: Colors.black26),
                              SizedBox(height: 12),
                              Text(
                                'No services yet',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black38),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final price = data['price'];
                        final description = data['description'] ?? '';
                        final priceText = price != null
                            ? '${(price as num).toStringAsFixed(3)} OMR'
                            : '';

                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.local_laundry_service_outlined,
                                      size: 20,
                                      color: Color(0xFF2C2C54)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2),
                                            child: Text(
                                              description,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (priceText.isNotEmpty)
                                    Text(
                                      priceText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2C2C54),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert,
                                        size: 20, color: Colors.black45),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditServiceSheet(
                                          docId: doc.id,
                                          currentName: name,
                                          currentPrice: price != null
                                              ? (price as num).toDouble()
                                              : 0.0,
                                          currentDescription: description,
                                          currentCategory: data['category'] as String? ?? '',
                                          currentCategoryLabel: data['categoryLabel'] as String? ?? '',
                                        );
                                      } else if (value == 'delete') {
                                        _confirmDeleteService(doc.id, name);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined,
                                                size: 18,
                                                color: Color(0xFF2C2C54)),
                                            SizedBox(width: 10),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                size: 18,
                                                color: Colors.redAccent),
                                            SizedBox(width: 10),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Delete service ─────────────────────────────────────────────────────────
  Future<void> _confirmDeleteService(String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: Text(
            'Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _uid == null) return;
    try {
      await _db.deleteService(_uid!, docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Edit service bottom sheet ──────────────────────────────────────────────
  void _showEditServiceSheet({
    required String docId,
    required String currentName,
    required double currentPrice,
    required String currentDescription,
    required String currentCategory,
    required String currentCategoryLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return _EditServiceSheet(
          uid: _uid!,
          docId: docId,
          currentName: currentName,
          currentPrice: currentPrice,
          currentDescription: currentDescription,
          currentCategory: currentCategory,
          currentCategoryLabel: currentCategoryLabel,
          db: _db,
          onSuccess: () {
            Navigator.pop(sheetCtx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service updated!'),
                  backgroundColor: Color(0xFF2C2C54),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: const Color(0xFF2C2C54),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 60, color: Colors.white54),
            SizedBox(height: 10),
            Text(
              'Tap to add shop photo',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Service Sheet — dedicated StatefulWidget to avoid controller lifecycle
// issues that cause the '_dependents.isEmpty' assertion crash on swipe-dismiss.
// ─────────────────────────────────────────────────────────────────────────────

// Re-use the same service catalogue and colour map from add_laundry_service_page
class _ServiceOption {
  final String name;
  final String category;
  final String categoryLabel;
  const _ServiceOption(this.name, this.category, this.categoryLabel);
}

const _kServices = [
  _ServiceOption('Shirt Cleaning',             'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Trouser Cleaning',           'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Suit Dry Cleaning',          'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Dress Cleaning',             'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Jacket / Coat Cleaning',     'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Abaya / Dishdasha Cleaning', 'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Sportswear Cleaning',        'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('School Uniform Cleaning',    'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('T-Shirt Cleaning',           'cloth_cleaning',   'Cloth Cleaning'),
  _ServiceOption('Blanket Washing',            'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Bed Sheet Cleaning',         'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Duvet / Comforter Cleaning', 'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Pillow Cover Washing',       'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Curtain Cleaning',           'blanket_cleaning', 'Blanket Cleaning'),
  _ServiceOption('Carpet Cleaning',            'blanket_cleaning', 'Blanket Cleaning'),
];

const _kCategoryColor = {
  'cloth_cleaning':   Color(0xFF1A1AE6),
  'blanket_cleaning': Color(0xFF2C7A4B),
};

class _EditServiceSheet extends StatefulWidget {
  final String uid;
  final String docId;
  final String currentName;
  final double currentPrice;
  final String currentDescription;
  final String currentCategory;
  final String currentCategoryLabel;
  final DatabaseService db;
  final VoidCallback onSuccess;

  const _EditServiceSheet({
    required this.uid,
    required this.docId,
    required this.currentName,
    required this.currentPrice,
    required this.currentDescription,
    required this.currentCategory,
    required this.currentCategoryLabel,
    required this.db,
    required this.onSuccess,
  });

  @override
  State<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends State<_EditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;

  _ServiceOption? _selectedService;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
        text: widget.currentPrice.toStringAsFixed(3));
    _descCtrl = TextEditingController(text: widget.currentDescription);

    // Pre-select the matching service option
    try {
      _selectedService = _kServices.firstWhere(
        (s) => s.name == widget.currentName,
      );
    } catch (_) {
      _selectedService = null;
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) return;

    setState(() => _saving = true);
    try {
      await widget.db.updateService(widget.uid, widget.docId, {
        'name':          _selectedService!.name,
        'category':      _selectedService!.category,
        'categoryLabel': _selectedService!.categoryLabel,
        'price':         double.tryParse(_priceCtrl.text.trim()) ?? widget.currentPrice,
        'description':   _descCtrl.text.trim(),
      });

      // Rebuild categories array on the shop doc so customer filters update
      await FirebaseFirestore.instance
          .collection('shopOwners')
          .doc(widget.uid)
          .collection('services')
          .get()
          .then((snap) {
        final cats = snap.docs
            .map((d) => (d.data()['category'] as String?) ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        return FirebaseFirestore.instance
            .collection('shopOwners')
            .doc(widget.uid)
            .update({'categories': cats});
      });

      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  List<DropdownMenuItem<_ServiceOption>> _buildDropdownItems() {
    final items = <DropdownMenuItem<_ServiceOption>>[];
    String? lastCategory;
    for (final service in _kServices) {
      if (service.category != lastCategory) {
        lastCategory = service.category;
        final headerColor =
            _kCategoryColor[service.category] ?? const Color(0xFF2C2C54);
        items.add(DropdownMenuItem<_ServiceOption>(
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
        ));
      }
      items.add(DropdownMenuItem<_ServiceOption>(
        value: service,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(service.name,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
      ));
    }
    return items;
  }

  InputDecoration _inputDec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2C2C54), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF2C2C54), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final categoryColor = _selectedService != null
        ? (_kCategoryColor[_selectedService!.category] ??
            const Color(0xFF2C2C54))
        : Colors.transparent;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Edit Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C54),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a service from the list to update it.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // ── Service dropdown ─────────────────────────────────────────────
            const Text('Service Name',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                          child: Text('Select a service…',
                              style: TextStyle(
                                  color: Colors.black38, fontSize: 14)),
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

            // ── Category badge ───────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _selectedService == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedService!.category == 'cloth_cleaning'
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
                    ),
            ),

            const SizedBox(height: 20),

            // ── Price ────────────────────────────────────────────────────────
            const Text('Price (OMR)',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  _inputDec(hint: '0.000', icon: Icons.attach_money_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────────
            const Text('Description (optional)',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDec(
                  hint: 'e.g. Includes washing and folding…',
                  icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C54),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
