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
          _shopImageUrl = data['shopImageUrl'];
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
                onTap: _pickAndUploadShopPhoto,
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
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentName);
    final priceCtrl =
        TextEditingController(text: currentPrice.toStringAsFixed(3));
    final descCtrl = TextEditingController(text: currentDescription);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;
              if (_uid == null) return;
              setSheetState(() => saving = true);
              bool success = false;
              try {
                await _db.updateService(_uid!, docId, {
                  'name': nameCtrl.text.trim(),
                  'price':
                      double.tryParse(priceCtrl.text.trim()) ?? currentPrice,
                  'description': descCtrl.text.trim(),
                });
                success = true;
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                // Only update sheet state if the sheet is still open
                if (!success) setSheetState(() => saving = false);
              }
              if (success) {
                // Pop the sheet first, then show snackbar on parent context
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service updated!'),
                      backgroundColor: Color(0xFF2C2C54),
                    ),
                  );
                }
              }
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 20),

                    // Service name
                    const Text('Service Name',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _sheetInputDecoration(
                          hint: 'e.g. Regular Cleaning',
                          icon: Icons.local_laundry_service_outlined),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    const Text('Price (OMR)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _sheetInputDecoration(
                          hint: '0.000',
                          icon: Icons.attach_money_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Description (optional)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _sheetInputDecoration(
                          hint: 'e.g. Includes washing and folding…',
                          icon: Icons.notes_outlined),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C54),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      priceCtrl.dispose();
      descCtrl.dispose();
    });
  }

  InputDecoration _sheetInputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF2C2C54), size: 20),
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
