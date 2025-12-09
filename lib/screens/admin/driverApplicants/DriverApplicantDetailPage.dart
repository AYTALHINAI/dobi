import 'package:flutter/material.dart';
import '../../../database.dart';

class DriverApplicantDetailPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const DriverApplicantDetailPage({super.key, required this.driverData});

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
        title: const Text("Driver Details"),
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
                  _infoRow("Full Name", driverData['fullName']),
                  _infoRow("Email", driverData['email']),
                  _infoRow("Phone", driverData['phone']),
                  _infoRow("Vehicle Type", driverData['vehicleType']),
                  _infoRow("Plate Number", driverData['plateNumber']),
                  _infoRow("License Number", driverData['licenseNumber']),
                  _infoRow("Application Status", driverData['applicationStatus']),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await dbService.updateDriverStatus(driverData['uid'], "approved");
                      showNotification("Driver approved successfully!", color: Colors.green);
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
                      await dbService.updateDriverStatus(driverData['uid'], "rejected");
                      showNotification("Driver rejected successfully!", color: Colors.red);
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
