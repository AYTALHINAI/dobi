import '../../theme/user_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Governorate → Wilayat data (same as registration Step 2)
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, List<String>> _governorateWilayatMap = {
  'Muscat': ['Muttrah', 'Bawshar', 'Seeb', 'Al Amerat', 'Qurayyat'],
  'Dhofar': [
    'Salalah',
    'Taqah',
    'Mirbat',
    'Thumrait',
    'Sadah',
    'Rakhyut',
    'Dalkut',
    'Muqshin'
  ],
  'Musandam': ['Khasab', 'Bukha', 'Dibba Al Baya', 'Madha'],
  'Al Buraimi': ['Mahdah', 'Al Sinainah'],
  'Al Dakhiliyah': [
    'Nizwa',
    'Bahla',
    'Adam',
    'Izki',
    'Samail',
    'Bidbid',
    'Manah'
  ],
  'Al Dhahirah': ['Ibri', 'Yanqul', 'Dhank'],
  'North Al Batinah': [
    'Sohar',
    'Shinas',
    'Liwa',
    'Saham',
    'Al Khaburah',
    'Suwaiq'
  ],
  'South Al Batinah': [
    'Rustaq',
    'Nakhal',
    'Wadi Al Maawil',
    'Barka',
    'Al Musannah'
  ],
  'North Al Sharqiyah': [
    'Ibra',
    'Al Mudhaibi',
    'Bidiyah',
    'Qabil',
    'Wadi Bani Khalid',
    'Dema Wa Thaieen'
  ],
  'South Al Sharqiyah': [
    'Sur',
    'Jalan Bani Bu Ali',
    'Jalan Bani Bu Hassan',
    'Al Kamil Wal Wafi',
    'Masirah'
  ],
  'Al Wusta': ['Haima', 'Duqm', 'Mahout', 'Al Jazer', 'Ibra (Al Wusta)'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────────────────────

class UserPersonalInfoPage extends StatefulWidget {
  final bool isSetupMode;
  const UserPersonalInfoPage({super.key, this.isSetupMode = false});

  @override
  State<UserPersonalInfoPage> createState() => _UserPersonalInfoPageState();
}

class _UserPersonalInfoPageState extends State<UserPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Dropdown state
  String? _selectedGovernorate;
  String? _selectedWilayat;

  // Location
  LatLng? _pickedLocation;

  bool _loading = true;
  bool _saving = false;

  List<String> get _governorates => _governorateWilayatMap.keys.toList();
  List<String> get _wilayats =>
      _selectedGovernorate != null
          ? _governorateWilayatMap[_selectedGovernorate]!
          : [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.getUserDoc(uid);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        _nameCtrl.text = data['fullName'] ?? data['displayName'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _emailCtrl.text =
            data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
        _addressCtrl.text = data['address'] ?? '';

        // Restore dropdown selections
        final gov = data['governorate'] as String?;
        if (gov != null && _governorateWilayatMap.containsKey(gov)) {
          _selectedGovernorate = gov;
          final wil = data['wilayat'] as String?;
          if (wil != null &&
              _governorateWilayatMap[gov]!.contains(wil)) {
            _selectedWilayat = wil;
          }
        }

        // Restore map pin
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat != null && lng != null) {
          _pickedLocation = LatLng(lat, lng);
        }
      } else if (widget.isSetupMode) {
        // New Google user — pre-fill name & email from Firebase Auth
        final firebaseUser = FirebaseAuth.instance.currentUser;
        _nameCtrl.text = firebaseUser?.displayName ?? '';
        _emailCtrl.text = firebaseUser?.email ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── Location picker ─────────────────────────────────────────────────────────
  Future<void> _openLocationPicker() async {
    final initial = _pickedLocation ??
        const LatLng(23.5880, 58.3829); // Muscat default

    final result = await Navigator.push<LatLng>(
      context,
      userPageRoute((_) => _LocationPickerPage(initialLocation: initial)),
    );

    if (result != null && mounted) {
      setState(() => _pickedLocation = result);
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = _uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      // Phone uniqueness check
      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        final taken = await _db.checkPhoneExistsForOtherUser(phone, uid);
        if (taken && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This phone number is already linked to another account.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _saving = false);
          return;
        }
      }

      await _db.updateUserFields(uid, {
        'fullName': _nameCtrl.text.trim(),
        'displayName': _nameCtrl.text.trim(),
        'phone': phone,
        'address': _addressCtrl.text.trim(),
        'governorate': _selectedGovernorate ?? '',
        'wilayat': _selectedWilayat ?? '',
        if (_pickedLocation != null) 'latitude': _pickedLocation!.latitude,
        if (_pickedLocation != null) 'longitude': _pickedLocation!.longitude,
        if (widget.isSetupMode) 'isNewGoogleUser': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isSetupMode
                  ? 'Profile complete! Welcome to Dobbie 🎉'
                  : 'Personal info updated successfully.',
            ),
            backgroundColor: context.uiPrimary,
          ),
        );
        if (widget.isSetupMode) {
          // Replace the entire navigation stack — user goes to home
          Navigator.pushReplacementNamed(context, '/home/user');
        } else {
          Navigator.pop(context);
        }
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        // In setup mode, the user must not go back — hide the back button
        automaticallyImplyLeading: !widget.isSetupMode,
        leading: widget.isSetupMode
            ? null
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.uiFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: context.uiTextPrimary),
                ),
              ),
        title: Text(
          widget.isSetupMode ? 'Complete Your Profile' : 'Personal Info',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.uiTextPrimary),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: context.uiPrimary))
          : Form(
              key: _formKey,
              child: ListView(
                padding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // ── Basic Info ───────────────────────────────────────────
                  _SectionTitle(title: 'Basic Information'),
                  SizedBox(height: 14),
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
                        return 'Name can only contain letters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14),
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                        return 'Phone must contain numbers only';
                      }
                      if (v.length != 8) {
                        return 'Phone number must be exactly 8 digits';
                      }
                      if (!v.startsWith('9') && !v.startsWith('7')) {
                        return 'Phone number must start with 7 or 9';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  SizedBox(height: 28),

                  // ── Address ──────────────────────────────────────────────
                  _SectionTitle(title: 'Address'),
                  SizedBox(height: 14),

                  // Governorate dropdown
                  _buildDropdown(
                    value: _selectedGovernorate,
                    hint: 'Select Governorate',
                    icon: Icons.map_outlined,
                    items: _governorates,
                    onChanged: (val) => setState(() {
                      _selectedGovernorate = val;
                      _selectedWilayat = null; // reset dependent
                    }),
                  ),
                  SizedBox(height: 14),

                  // Wilayat dropdown (dependent on governorate)
                  _buildDropdown(
                    value: _selectedWilayat,
                    hint: _selectedGovernorate == null
                        ? 'Select Governorate First'
                        : 'Select Wilayat',
                    icon: Icons.location_city_outlined,
                    items: _wilayats,
                    enabled: _selectedGovernorate != null,
                    onChanged: _selectedGovernorate == null
                        ? null
                        : (val) => setState(() => _selectedWilayat = val),
                  ),
                  SizedBox(height: 14),

                  _buildTextField(
                    controller: _addressCtrl,
                    label: 'House / Building Number (Optional)',
                    icon: Icons.home_outlined,
                  ),
                  SizedBox(height: 28),

                  // ── Delivery Location ────────────────────────────────────
                  Row(
                    children: [
                      _SectionTitle(title: 'Delivery Location'),
                      SizedBox(width: 8),
                      if (_pickedLocation == null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 12, color: Colors.red.shade600),
                              SizedBox(width: 4),
                              Text(
                                'Required for ordering',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap the map to open the location picker and pin your delivery address.',
                    style:
                        TextStyle(fontSize: 12, color: context.uiTextSecondary),
                  ),
                  SizedBox(height: 12),

                  // Map preview / placeholder — tapping opens full-screen picker
                  GestureDetector(
                    onTap: _openLocationPicker,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: context.uiFill,
                        border: Border.all(
                          color: _pickedLocation == null
                              ? Colors.red.shade300
                              : context.uiPrimary
                                  .withValues(alpha: 0.3),
                          width: _pickedLocation == null ? 2 : 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedLocation != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _pickedLocation!,
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('delivery'),
                                      position: _pickedLocation!,
                                      icon: BitmapDescriptor
                                          .defaultMarkerWithHue(
                                              BitmapDescriptor.hueBlue),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  zoomGesturesEnabled: false,
                                  myLocationButtonEnabled: false,
                                  myLocationEnabled: false,
                                  liteModeEnabled: false,
                                ),
                                // "Change" chip overlay
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: context.uiPrimary,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_location_alt,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Change',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      Icons.add_location_alt_outlined,
                                      size: 36,
                                      color: context.uiPrimary),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to set your delivery location',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.uiTextHint),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  if (_pickedLocation != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: context.uiPrimary),
                        SizedBox(width: 6),
                        Text(
                          'Location pinned — tap map to change',
                          style:
                              TextStyle(fontSize: 12, color: context.uiTextSecondary),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 36),

                  // ── Save button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.uiPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              widget.isSetupMode ? 'Get Started' : 'Save Changes',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
          fontSize: 14,
          color: enabled ? context.uiTextPrimary : context.uiTextHint),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: context.uiTextSecondary),
        prefixIcon: Icon(icon,
            size: 20,
            color: enabled ? context.uiPrimary : context.uiTextHint),
        filled: true,
        fillColor:
            enabled ? context.uiFill : context.uiFill,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              BorderSide(color: context.uiPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? context.uiFill : context.uiFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.transparent : Colors.transparent,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            size: 20,
            color: enabled ? context.uiPrimary : context.uiTextHint,
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: context.uiPrimary, width: 1.5),
          ),
        ),
        hint: Text(
          hint,
          style: TextStyle(
            fontSize: 13,
            color: enabled ? context.uiTextSecondary : context.uiTextHint,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: context.uiTextPrimary,
        ),
        dropdownColor: context.uiSurface,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: enabled ? context.uiTextSecondary : context.uiTextHint,
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.uiTextPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen location picker (same pattern as shopOwner_profile_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  const _LocationPickerPage({required this.initialLocation});

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled. Please enable GPS.'),
              backgroundColor: context.uiTextPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied. Please allow it in Settings.'),
              backgroundColor: context.uiTextPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLocation = latLng);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.uiPrimary,
        foregroundColor: Colors.white,
        title: Text(
          'Pin Delivery Location',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _selectedLocation),
            child: Text(
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
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                onDragEnd: (pos) =>
                    setState(() => _selectedLocation = pos),
              ),
            },
            onTap: (pos) => setState(() => _selectedLocation = pos),
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            liteModeEnabled: false,
          ),
          // Instruction banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: context.uiSurface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: context.uiPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap the map or drag the pin to set your delivery location',
                      style:
                          TextStyle(fontSize: 12, color: context.uiTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Use Current Location button ─────────────────────────────
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _fetchingLocation ? null : _goToCurrentLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                    color: context.uiPrimary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _fetchingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Use Current Location',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
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
