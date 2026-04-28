import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database.dart';

class ShopOwnerOrdersPage extends StatefulWidget {
  const ShopOwnerOrdersPage({super.key});

  @override
  State<ShopOwnerOrdersPage> createState() => _ShopOwnerOrdersPageState();
}

class _ShopOwnerOrdersPageState extends State<ShopOwnerOrdersPage> {
  final String? shopId = FirebaseAuth.instance.currentUser?.uid;


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
                      'Orders',
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


            // ── Orders list or Empty state ───────────────────────
            Expanded(
              child: shopId == null
                  ? const Center(child: Text("Not logged in"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService().getShopOrdersStream(shopId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final rawDocs = snapshot.data?.docs ?? [];
                        // Sort newest-first client-side (avoids composite index requirement)
                        final docs = [...rawDocs]..sort((a, b) {
                            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
                            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
                            if (aTs == null && bTs == null) return 0;
                            if (aTs == null) return 1;
                            if (bTs == null) return -1;
                            return (bTs as Timestamp).compareTo(aTs as Timestamp);
                          });

                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final orderDoc = docs[index];
                            final orderData = orderDoc.data() as Map<String, dynamic>;
                            return _OrderTile(
                              orderId: orderDoc.id,
                              orderData: orderData,
                            );
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
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders will appear here once received.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─── Order tile ───────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _OrderTile({
    required this.orderId,
    required this.orderData,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'picked': return Colors.blue;
      case 'in_progress': return Colors.indigo;
      case 'ready': return Colors.teal;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      default: return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    final customerName = orderData['customerName'] ?? orderData['userName'] ?? 'Customer';
    final totalPrice = orderData['totalPrice'] ?? 0.0;
    final scheduledDate = orderData['scheduledDate'] ?? 'Not set';
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Customer Name and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Items List
          Text(
            'Items:',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...items.map((item) {
            final name = item['serviceName'] ?? 'Service';
            final qty = item['quantity'] ?? 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• ${qty}x $name',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 12),
          
          // Details: Date and Total Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Scheduled: $scheduledDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'RM ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          // Action Buttons / Labels
          _buildActionSection(context, status),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, String status) {
    if (status == 'ready') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Waiting for Driver',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      );
    } else if (status == 'delivered') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Completed ✓',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      );
    }

    String buttonText = '';
    String nextStatus = '';
    
    if (status == 'pending') {
      buttonText = 'Confirm & Pick Up';
      nextStatus = 'picked';
    } else if (status == 'picked') {
      buttonText = 'Start Processing';
      nextStatus = 'in_progress';
    } else if (status == 'in_progress') {
      buttonText = 'Mark as Ready';
      nextStatus = 'ready';
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          if (nextStatus.isNotEmpty) {
            try {
              await DatabaseService().updateOrderStatus(orderId, nextStatus);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update status: $e')),
              );
            }
          }
        },
        child: Text(
          buttonText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
