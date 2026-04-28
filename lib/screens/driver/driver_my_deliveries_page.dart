import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database.dart';
import 'driver_widgets.dart';

class DriverMyDeliveriesPage extends StatelessWidget {
  final String uid;
  const DriverMyDeliveriesPage({super.key, required this.uid});

  /// Sort docs newest-first client-side (avoids composite Firestore index).
  List<QueryDocumentSnapshot> _sorted(List<QueryDocumentSnapshot> raw) {
    return [...raw]..sort((a, b) {
        final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
        final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return (bTs as Timestamp).compareTo(aTs as Timestamp);
      });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getDriverActiveOrders(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black87),
          );
        }

        final docs = _sorted(snapshot.data?.docs ?? []);
        if (docs.isEmpty) {
          return buildDriverEmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No Active Deliveries',
            subtitle: 'Accept an order from the Available tab.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final orderDoc  = docs[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            final status    = orderData['status'] ?? '';

            Widget? actionWidget;
            if (status == 'picked') {
              actionWidget = ElevatedButton(
                onPressed: () async {
                  await DatabaseService()
                      .updateOrderStatus(orderDoc.id, 'delivered');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Mark as Delivered'),
              );
            }

            return DriverOrderCard(
              orderData: orderData,
              actionWidget: actionWidget,
            );
          },
        );
      },
    );
  }
}
