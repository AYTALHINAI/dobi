import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../database.dart';

class ShopOwnerFeedbackPage extends StatefulWidget {
  const ShopOwnerFeedbackPage({super.key});

  @override
  State<ShopOwnerFeedbackPage> createState() => _ShopOwnerFeedbackPageState();
}

class _ShopOwnerFeedbackPageState extends State<ShopOwnerFeedbackPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _shopId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 28, color: Colors.black87),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Feedback',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Invisible spacer to balance the back button
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search feedback....',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Feedbacks list or Empty state ───────────────────────
            Expanded(
              child: _shopId == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _db.getShopFeedbacksStream(_shopId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Something went wrong. Please try again.'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          return bTime.compareTo(aTime);
                        });

                        final query = _searchController.text.toLowerCase();

                        final filteredDocs = query.isEmpty 
                            ? docs 
                            : docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final comment = (data['comment'] ?? '').toString().toLowerCase();
                                return comment.contains(query);
                              }).toList();

                        if (filteredDocs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _FeedbackTile(feedbackId: doc.id, feedbackData: data);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.feedback_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No feedback yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Feedback will appear here once received.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback tile ───────────────────────────────────────────────────────────────

class _FeedbackTile extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> feedbackData;

  const _FeedbackTile({required this.feedbackId, required this.feedbackData});

  @override
  Widget build(BuildContext context) {
    final comment = feedbackData['comment'] ?? '';
    final rating = (feedbackData['rating'] ?? 0).toString();
    final userId = feedbackData['userId'] ?? '';
    
    // Format the date
    String dateStr = '';
    if (feedbackData['createdAt'] != null) {
      final timestamp = feedbackData['createdAt'] as Timestamp;
      final date = timestamp.toDate();
      dateStr = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE05555),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // We fetch the user's name using FutureBuilder
                FutureBuilder<DocumentSnapshot>(
                  future: DatabaseService().getUserDoc(userId),
                  builder: (context, snapshot) {
                    String userName = 'Customer';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      userName = userData['fullName'] ?? userData['displayName'] ?? 'Customer';
                    }
                    return Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  comment.isEmpty ? 'No comment' : comment,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (feedbackData['shopReply'] != null && feedbackData['shopReply'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Reply:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedbackData['shopReply'],
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showReplyDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.reply, size: 14, color: Color(0xFFE05555)),
                        SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE05555)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Date etc
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF5C518), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: Color(0xFFF5C518),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final TextEditingController replyController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Reply to Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: TextField(
                controller: replyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Type your reply here...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05555),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    final replyText = replyController.text.trim();
                    if (replyText.isEmpty) return;

                    setState(() => isSubmitting = true);
                    try {
                      await DatabaseService().replyToFeedback(feedbackId, replyText);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
