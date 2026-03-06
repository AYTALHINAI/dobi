import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  Future<void> _loadShopInfo() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shopOwners')
          .doc(_uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
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

      // Persist to Firestore so it loads next time
      await FirebaseFirestore.instance
          .collection('shopOwners')
          .doc(_uid)
          .update({'shopImageUrl': url});

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
                stream: FirebaseFirestore.instance
                    .collection('shopOwners')
                    .doc(_uid)
                    .collection('services')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
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
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final price = data['price'];
                        final priceText = price != null
                            ? '${(price as num).toStringAsFixed(3)} OMR'
                            : '';

                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.local_laundry_service_outlined,
                                      size: 20,
                                      color: Color(0xFF2C2C54)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
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
