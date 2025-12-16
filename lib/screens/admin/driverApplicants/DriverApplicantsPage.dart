import 'package:flutter/material.dart';
import '../../../database.dart';
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
      appBar: AppBar(title: const Text("Driver Applicants")),
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
                      tileColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A237E),
                        child: Text(
                          (driver['fullName'] ?? 'D')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        driver['fullName'] ?? "No Name",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver['email'] ?? ""),
                          Text(
                            driver['vehicleType'] ?? "",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminDriverDetail,
                          arguments: driver,
                        ).then((_) => fetchApplicants());
                      },
                    );
                  },
                ),
    );
  }
}
