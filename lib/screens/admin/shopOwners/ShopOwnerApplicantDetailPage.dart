import 'package:flutter/material.dart';
import '../../../database.dart';

class ShopOwnerApplicantDetailPage extends StatelessWidget {
  final Map<String, dynamic> ownerData;
  const ShopOwnerApplicantDetailPage({super.key, required this.ownerData});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    void showNotification(String message, {Color color = Colors.green}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Owner Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _infoRow("Full Name", ownerData['fullName']),
                  _infoRow("Email", ownerData['email']),
                  _infoRow("Phone", ownerData['phone']),
                  _infoRow("Shop Name", ownerData['shopName']),
                  _infoRow("Shop Address", ownerData['shopAddress']),
                  _infoRow("Application Status", ownerData['applicationStatus']),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await dbService.updateShopOwnerStatus(ownerData['uid'], "approved");
                      showNotification("Shop Owner approved successfully!", color: Colors.green);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Approve",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await dbService.updateShopOwnerStatus(ownerData['uid'], "rejected");
                      showNotification("Shop Owner rejected successfully!", color: Colors.red);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
