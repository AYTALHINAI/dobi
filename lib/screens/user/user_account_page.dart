import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
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

  Future<void> _deletePhoto(String? currentUrl) async {
    final user = _user;
    if (user == null || currentUrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Profile Photo'),
        content: const Text(
            'Are you sure you want to remove your profile photo?'),
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
      // Delete the file from Firebase Storage
      await FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile_photo.jpg')
          .delete();
    } catch (_) {
      // File may not exist in storage — that's fine
    }
    try {
      await _db.deleteUserProfileImage(user.uid);
      if (mounted) setState(() => _pickedImage = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      }
    }
  }

  void _showPhotoOptions(String? currentUrl) {
    final primaryColor = UserTheme.of(context).isDark
        ? const Color(0xFF7B7BFF)
        : const Color(0xFF1A1AE6);

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: primaryColor),
              title: const Text('Change Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto();
              },
            ),
            if (currentUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto(currentUrl);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to theme changes so the page itself re-renders when toggled.
    final themeNotifier = UserTheme.of(context);
    final isDark = themeNotifier.isDark;

    // Semantic colours — resolve once and use throughout.
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor =
        isDark ? const Color(0xFF7B7BFF) : const Color(0xFF1A1AE6);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.black45;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: avatar + name + email ──────────────────────────────
              StreamBuilder<DocumentSnapshot>(
                stream: _user != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  final data =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final displayName =
                      (data?['displayName']?.toString().trim().isNotEmpty ==
                              true)
                          ? data!['displayName'].toString().trim()
                          : (_user?.displayName?.trim().isNotEmpty == true
                              ? _user!.displayName!.trim()
                              : 'User');
                  final profileImageUrl =
                      data?['profileImageUrl'] as String?;

                  return Row(
                    children: [
                      // Tappable avatar with camera badge
                      GestureDetector(
                        onTap: () => _showPhotoOptions(profileImageUrl),
                        child: Stack(
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.1),
                                border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _pickedImage != null && _uploadingPhoto
                                  ? Image.file(_pickedImage!,
                                      fit: BoxFit.cover)
                                  : profileImageUrl != null
                                      ? Image.network(
                                          profileImageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, prog) =>
                                              prog == null
                                                  ? child
                                                  : const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth:
                                                                  2)),
                                          errorBuilder: (_, __, ___) => Icon(
                                              Icons.person,
                                              size: 42,
                                              color: primaryColor),
                                        )
                                      : Icon(Icons.person,
                                          size: 42, color: primaryColor),
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
                                          color: Colors.white,
                                          strokeWidth: 2.5),
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
                                decoration: BoxDecoration(
                                  color: primaryColor,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (_email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                _email,
                                style: TextStyle(
                                    fontSize: 12, color: textSecondary),
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
              Divider(color: dividerColor),
              const SizedBox(height: 8),

              // ── Menu items ────────────────────────────────────────────────
              _MenuItem(
                icon: Icons.person_pin_outlined,
                label: 'Personal Info',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  userPageRoute((_) => const UserPersonalInfoPage()),
                ),
              ),
              _MenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About App',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  userPageRoute((_) => const AboutAppPage()),
                ),
              ),

              // Dark / Light Mode toggle
              _MenuItem(
                icon:
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                label: isDark ? 'Light Mode' : 'Dark Mode',
                isDark: isDark,
                onTap: () => themeNotifier.toggle(),
                trailing: _ThemeToggleSwitch(isDark: isDark),
              ),

              const SizedBox(height: 8),
              Divider(color: dividerColor),
              const SizedBox(height: 8),

              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                iconColor: Colors.redAccent,
                labelColor: Colors.redAccent,
                isDark: isDark,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dark/Light Mode animated switch ─────────────────────────────────────────

class _ThemeToggleSwitch extends StatelessWidget {
  final bool isDark;
  const _ThemeToggleSwitch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isDark ? const Color(0xFF7B7BFF) : Colors.grey.shade300,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment:
            isDark ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Menu item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.iconColor,
    this.labelColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final defaultFg = isDark ? Colors.white : Colors.black87;
    final resolvedIcon = iconColor ?? defaultFg;
    final resolvedLabel = labelColor ?? defaultFg;
    final chevronColor = isDark ? Colors.grey.shade600 : Colors.black26;

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
                color: resolvedIcon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: resolvedIcon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: resolvedLabel,
                ),
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: chevronColor),
          ],
        ),
      ),
    );
  }
}
