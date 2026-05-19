import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _db = DatabaseService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _emailEnabled = true;
  bool _inAppEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_uid == null) return;
    try {
      final doc = await _db.getUserDoc(_uid!);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _emailEnabled = data['emailNotificationsEnabled'] as bool? ?? true;
          _inAppEnabled = data['inAppNotificationsEnabled'] as bool? ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String field, bool value) async {
    if (_uid == null) return;
    try {
      await _db.updateUserFields(_uid!, {field: value});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.uiPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.uiTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: context.uiTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure Alerts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.uiTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: context.uiSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.uiDivider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // In-App Notification toggle
                        _buildSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'In-App Notifications',
                          subtitle: 'Receive real-time progress updates inside the app.',
                          value: _inAppEnabled,
                          onChanged: (val) {
                            setState(() => _inAppEnabled = val);
                            _updatePreference('inAppNotificationsEnabled', val);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(color: context.uiDivider, height: 1),
                        ),
                        // Email Notification toggle
                        _buildSwitchTile(
                          icon: Icons.mail_outline_rounded,
                          title: 'Email Notifications',
                          subtitle: 'Get tracking updates sent to your registered email.',
                          value: _emailEnabled,
                          onChanged: (val) {
                            setState(() => _emailEnabled = val);
                            _updatePreference('emailNotificationsEnabled', val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Preferences are automatically saved. Toggling notifications off will prevent you from receiving status update alerts for your orders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.uiTextHint,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primary = context.uiPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.uiTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.uiTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
