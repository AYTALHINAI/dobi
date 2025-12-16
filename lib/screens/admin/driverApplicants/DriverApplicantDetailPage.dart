import 'package:flutter/material.dart';
import '../../../database.dart';

class DriverApplicantDetailPage extends StatelessWidget {
  final Map<String, dynamic> driverData;
  const DriverApplicantDetailPage({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    const Color primaryDeep = Color(0xFF1A237E);

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
        backgroundColor: primaryDeep,
        foregroundColor: Colors.white,
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
                  // Personal Information Section
                  _sectionHeader("Personal Information", Icons.person),
                  _infoRow("Full Name", driverData['fullName']),
                  _infoRow("Email", driverData['email']),
                  _infoRow("Phone", driverData['phone']),
                  
                  const SizedBox(height: 20),
                  
                  // Vehicle Information Section
                  _sectionHeader("Vehicle Information", Icons.delivery_dining),
                  _infoRow("Vehicle Type", driverData['vehicleType']),
                  _infoRow("Plate Number", driverData['plateNumber']),
                  
                  const SizedBox(height: 20),
                  
                  // License Section
                  _sectionHeader("License", Icons.badge),
                  _infoRow("License Number", driverData['licenseNumber']),
                  
                  const SizedBox(height: 20),
                  
                  // Status Section
                  _sectionHeader("Application Status", Icons.assignment),
                  _statusChip(driverData['applicationStatus']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      "Approve",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await dbService.updateDriverStatus(driverData['uid'], "approved");
                      showNotification("Driver approved successfully!", color: Colors.green);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await dbService.updateDriverStatus(driverData['uid'], "rejected");
                      showNotification("Driver rejected.", color: Colors.red);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : "Not provided",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String? status) {
    Color chipColor;
    String displayStatus = status ?? "Unknown";
    
    switch (status?.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'approved':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "Status",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: chipColor),
            ),
            child: Text(
              displayStatus.toUpperCase(),
              style: TextStyle(
                color: chipColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
