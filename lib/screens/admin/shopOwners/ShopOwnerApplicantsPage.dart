import 'package:flutter/material.dart';
import '../../../database.dart';
import '../../../routes/app_routes.dart';

class ShopOwnerApplicantsPage extends StatefulWidget {
  const ShopOwnerApplicantsPage({super.key});

  @override
  State<ShopOwnerApplicantsPage> createState() => _ShopOwnerApplicantsPageState();
}

class _ShopOwnerApplicantsPageState extends State<ShopOwnerApplicantsPage> {
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
      var snapshot = await dbService.getPendingShopOwners();
      applicants = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching shop owner applicants: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Owner Applicants")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicants.isEmpty
              ? const Center(child: Text("No pending applicants."))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: applicants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var owner = applicants[index];
                    return ListTile(
                      tileColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A237E),
                        child: Text(
                          (owner['ownerName'] ?? 'S')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        owner['shopName'] ?? "No Shop Name",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(owner['ownerName'] ?? "No Owner Name"),
                          Text(
                            "${owner['governorate'] ?? ''}, ${owner['wilayat'] ?? ''}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminShopOwnerDetail,
                          arguments: owner,
                        ).then((_) => fetchApplicants());
                      },
                    );
                  },
                ),
    );
  }
}
