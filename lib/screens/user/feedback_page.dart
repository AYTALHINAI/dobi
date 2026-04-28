import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';

class FeedbackPage extends StatefulWidget {
  final String orderId;
  final String shopId;
  final String shopName;

  const FeedbackPage({
    Key? key,
    required this.orderId,
    required this.shopId,
    required this.shopName,
  }) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  String _getRatingText() {
    switch (_selectedRating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await DatabaseService().submitFeedback({
        'orderId': widget.orderId,
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'userId': uid,
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thank You! 🌟', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Your feedback helps us improve.', style: TextStyle(fontSize: 16)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to orders
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        title: Text('Rate Your Experience', style: TextStyle(color: context.uiTextPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: context.uiBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.uiTextPrimary),
      ),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator(color: context.uiPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.shopName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.uiTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= _selectedRating;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? Colors.amber : context.uiTextHint,
                            size: 48,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating Text
                  Text(
                    _getRatingText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.uiPrimary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Comment Box
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Write a comment (optional)',
                      style: TextStyle(fontSize: 14, color: context.uiTextSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us about your experience...',
                      hintStyle: TextStyle(color: context.uiTextHint),
                      filled: true,
                      fillColor: context.uiSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.uiDivider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.uiDivider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.uiPrimary)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _isSubmitting
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: context.uiSurface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }
}
