import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../routes/app_routes.dart';

class ShopOwnerProfilePage extends StatefulWidget {
  const ShopOwnerProfilePage({super.key});

  @override
  State<ShopOwnerProfilePage> createState() => _ShopOwnerProfilePageState();
}

class _ShopOwnerProfilePageState extends State<ShopOwnerProfilePage> {
  // ── State ──────────────────────────────────────────────────────────────────
  String _shopName = '';
  String _ownerName = '';
  String _shopPhone = '';
  String _email = '';
  String _shopAddress = '';
  String _governorate = '';
  String _wilayat = '';
  double? _latitude;
  double? _longitude;

  File? _pickedImage;
  bool _loading = true;
  bool _savingLocation = false;

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
          _ownerName = data['ownerName'] ?? '';
          _shopPhone = data['shopPhone'] ?? '';
          _email = data['email'] ?? '';
          _shopAddress = data['shopAddress'] ?? '';
          _governorate = data['governorate'] ?? '';
          _wilayat = data['wilayat'] ?? '';
          _latitude = (data['latitude'] as num?)?.toDouble();
          _longitude = (data['longitude'] as num?)?.toDouble();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  // ── Location picker ────────────────────────────────────────────────────────
  Future<void> _openLocationPicker() async {
    final initial = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(23.5859, 58.4059); // Default: Muscat, Oman

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerPage(initialLocation: initial),
      ),
    );

    if (result != null && _uid != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _savingLocation = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('shopOwners')
            .doc(_uid)
            .update({
          'latitude': result.latitude,
          'longitude': result.longitude,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location saved!'),
              backgroundColor: Color(0xFF2C2C54),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save location: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _savingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + shop name ────────────────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                  border: Border.all(
                                      color: Colors.grey.shade300, width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _pickedImage != null
                                    ? Image.file(_pickedImage!,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.person,
                                        size: 54, color: Colors.grey),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2C2C54),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shopName.isEmpty
                                    ? 'Shop Name'
                                    : _shopName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2C54),
                                ),
                              ),
                              if (_ownerName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  _ownerName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ── Shop Details ──────────────────────────────────────
                    const Text(
                      'Shop Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Shop Phone',
                        value: _shopPhone),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _email),
                    _InfoRow(
                        icon: Icons.home_work_outlined,
                        label: 'Shop Address',
                        value: _shopAddress),
                    _InfoRow(
                        icon: Icons.map_outlined,
                        label: 'Governorate',
                        value: _governorate),
                    _InfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'Wilayat',
                        value: _wilayat),

                    const SizedBox(height: 20),

                    // ── Location on Map ───────────────────────────────────
                    const Text(
                      'Shop Location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Map preview or placeholder
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFF5F5F7),
                          border: Border.all(
                              color: const Color(0xFF2C2C54).withValues(alpha: 0.25),
                              width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _latitude != null && _longitude != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(_latitude!, _longitude!),
                                      zoom: 15,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('shop'),
                                        position:
                                            LatLng(_latitude!, _longitude!),
                                      ),
                                    },
                                    zoomControlsEnabled: false,
                                    scrollGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    zoomGesturesEnabled: false,
                                    myLocationButtonEnabled: false,
                                    liteModeEnabled: true,
                                  ),
                                  // Tap overlay
                                  Container(
                                    alignment: Alignment.bottomRight,
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C2C54),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_location_alt,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Change',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_savingLocation)
                                    Container(
                                      color: Colors.black26,
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white)),
                                    ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_location_alt_outlined,
                                        size: 36,
                                        color: Color(0xFF2C2C54)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to set shop location',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Logout ────────────────────────────────────────────
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Row(
                          children: const [
                            Icon(Icons.logout,
                                color: Colors.redAccent, size: 26),
                            SizedBox(width: 14),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2C2C54)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location Picker Page ─────────────────────────────────────────────────────

class _LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  const _LocationPickerPage({required this.initialLocation});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
        title: const Text(
          'Pin Shop Location',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedLocation),
            child: const Text(
              'Confirm',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (pos) =>
                    setState(() => _selectedLocation = pos),
              ),
            },
            onTap: (pos) => setState(() => _selectedLocation = pos),
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
          // Instruction banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF2C2C54)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap the map or drag the pin to set your shop location',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
