import 'package:flutter/material.dart';
import '../../../database.dart';
import '../../auth/driver/driver_registration_model.dart';
import '../../../routes/app_routes.dart';

class DriverApplicantsPage extends StatefulWidget {
  const DriverApplicantsPage({super.key});

  @override
  State<DriverApplicantsPage> createState() => _DriverApplicantsPageState();
}

class _DriverApplicantsPageState extends State<DriverApplicantsPage> {
  final DatabaseService dbService = DatabaseService();
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    setState(() => isLoading = true);
    try {
      // Fetch all drivers with pending status
      var snapshot = await dbService.getPendingDrivers();
      applicants = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching applicants: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Applicants"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicants.isEmpty
          ? const Center(child: Text("No pending applicants."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: applicants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          var driver = applicants[index];
          return ListTile(
            tileColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(driver['fullName'] ?? "No Name"),
            subtitle: Text(driver['email'] ?? ""),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.adminDriverDetail,
                arguments: driver,
              ).then((_) => fetchApplicants()); // refresh after approve/reject
            },
          );
        },
      ),
    );
  }
}
