import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../database.dart';
import 'about_app_page.dart';
import 'user_personal_info_page.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final _user = FirebaseAuth.instance.currentUser;
  final _db = DatabaseService();

  String _email = '';
  File? _pickedImage;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _email = _user?.email ?? '';
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = _user;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _uploadingPhoto = true;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile_photo.jpg');
      await ref.putFile(_pickedImage!);
      final url = await ref.getDownloadURL();

      await _db.updateUserProfileImage(user.uid, url);

      await _db.updateUserProfileImage(user.uid, url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: avatar + name + email ──────────────────────────────
              StreamBuilder<DocumentSnapshot>(
                stream: _user != null
                    ? FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final displayName = (data?['displayName']?.toString().trim().isNotEmpty == true)
                      ? data!['displayName'].toString().trim()
                      : (_user?.displayName?.trim().isNotEmpty == true
                          ? _user!.displayName!.trim()
                          : 'User');
                  final profileImageUrl = data?['profileImageUrl'] as String?;

                  return Row(
                    children: [
                      // Tappable avatar with camera badge
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1A1AE6).withValues(alpha: 0.1),
                                border: Border.all(
                                    color: const Color(0xFF1A1AE6).withValues(alpha: 0.3),
                                    width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _pickedImage != null && _uploadingPhoto
                                  // Local preview while uploading
                                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                  : profileImageUrl != null
                                      // Saved photo from Firebase
                                      ? Image.network(
                                          profileImageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, prog) => prog == null
                                              ? child
                                              : const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2)),
                                          errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person,
                                              size: 42,
                                              color: Color(0xFF1A1AE6)),
                                        )
                                      : const Icon(Icons.person, size: 42, color: Color(0xFF1A1AE6)),
                            ),
                            // Upload spinner
                            if (_uploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black38,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  ),
                                ),
                              ),
                            // Camera badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A1AE6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name + email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                _email,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),

              // ── Menu items ───────────────────────────────────────────────────
              _MenuItem(
                icon: Icons.person_pin_outlined,
                label: 'Personal Info',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserPersonalInfoPage()),
                ),
              ),
              _MenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About App',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AboutAppPage()),
                ),
              ),
              _MenuItem(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                onTap: () {}, // static for now
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                iconColor: Colors.redAccent,
                labelColor: Colors.redAccent,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu item ─────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.black87,
    this.labelColor = Colors.black87,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
