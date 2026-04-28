import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/user_theme.dart';
import '../../database.dart';
import '../../routes/app_routes.dart';
import 'feedback_page.dart';

class UserOrdersPage extends StatelessWidget {
  const UserOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: context.uiBackground,
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Orders',
          style: TextStyle(
            color: context.uiTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getUserOrdersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: context.uiTextSecondary)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.uiPrimary));
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: context.uiTextHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.uiTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your orders will appear here once you place one.',
                    style: TextStyle(fontSize: 13, color: context.uiTextHint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _OrderCard(
                orderData: data,
                onTap: () {
                  Navigator.push(
                    context,
                    userPageRoute((_) => OrderDetailPage(orderData: data)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onTap;

  const _OrderCard({required this.orderData, required this.onTap});

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
    final shopName = orderData['shopName'] ?? 'Unknown Shop';
    final totalPrice = orderData['totalPrice'] ?? 0.0;
    final createdAtRaw = orderData['createdAt'];
    
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.uiSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.uiDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shopName,
                    style: TextStyle(
                      color: context.uiTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : 'Unknown Date',
                  style: TextStyle(
                    color: context.uiTextSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RM ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: context.uiPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailPage({super.key, required this.orderData});

  List<String> get _statusSteps => ['pending', 'picked', 'in_progress', 'ready', 'delivered'];

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      default: return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
    final shopName = orderData['shopName'] ?? 'Unknown Shop';
    final paymentStatus = orderData['paymentStatus'] ?? 'unpaid';
    final scheduledDate = orderData['scheduledDate'] ?? 'Not set';
    final totalPrice = orderData['totalPrice'] ?? 0.0;
    final feedbackGiven = orderData['feedbackGiven'] == true;
    final orderId = orderData['orderId'] ?? '';

    final currentStepIndex = _statusSteps.indexOf(status);

    return Scaffold(
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.uiTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: context.uiTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Name & Scheduled Date
            Text(
              shopName,
              style: TextStyle(
                color: context.uiTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scheduled: $scheduledDate',
              style: TextStyle(
                color: context.uiTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Status Tracker
            Text(
              'Status',
              style: TextStyle(
                color: context.uiTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_statusSteps.length, (index) {
                final isCompleted = index <= currentStepIndex;
                final isLast = index == _statusSteps.length - 1;
                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? context.uiPrimary : context.uiFill,
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatStatus(_statusSteps[index]),
                            style: TextStyle(
                              fontSize: 10,
                              color: isCompleted ? context.uiPrimary : context.uiTextHint,
                              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < currentStepIndex ? context.uiPrimary : context.uiFill,
                            margin: const EdgeInsets.only(bottom: 16),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Item List
            Text(
              'Items',
              style: TextStyle(
                color: context.uiTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.uiSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.uiDivider),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(color: context.uiDivider, height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final serviceName = item['serviceName'] ?? 'Service';
                  final qty = item['quantity'] ?? 1;
                  final price = item['price'] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${qty}x $serviceName',
                          style: TextStyle(color: context.uiTextPrimary, fontSize: 15),
                        ),
                        Text(
                          'RM ${(price * qty).toStringAsFixed(2)}',
                          style: TextStyle(color: context.uiTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: context.uiTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: context.uiPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: TextStyle(
                    color: context.uiTextSecondary,
                    fontSize: 14,
                  ),
                ),
                if (paymentStatus == 'paid')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Paid ✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Feedback Button
            if (status == 'delivered')
              if (feedbackGiven)
                const Center(
                  child: Text(
                    'You have already rated this order ✓',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.uiPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        userPageRoute((_) => FeedbackPage(
                          orderId: orderId,
                          shopId: orderData['shopId'] ?? '',
                          shopName: shopName,
                        )),
                      );
                    },
                    child: const Text(
                      'Rate This Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
