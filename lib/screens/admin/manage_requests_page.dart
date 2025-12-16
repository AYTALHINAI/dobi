import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../database.dart';
import '../../routes/app_routes.dart';

class ManageRequestsPage extends StatefulWidget {
  const ManageRequestsPage({super.key});

  @override
  State<ManageRequestsPage> createState() => _ManageRequestsPageState();
}

class _ManageRequestsPageState extends State<ManageRequestsPage> {
  final DatabaseService dbService = DatabaseService();
  int _selectedIndex = 0;
  
  List<Map<String, dynamic>> driverApplicants = [];
  List<Map<String, dynamic>> shopOwnerApplicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllApplicants();
  }

  Future<void> _fetchAllApplicants() async {
    setState(() => isLoading = true);
    try {
      // Fetch driver applicants
      var driverSnapshot = await dbService.getPendingDrivers();
      driverApplicants = driverSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();

      // Fetch shop owner applicants
      var shopSnapshot = await dbService.getPendingShopOwners();
      shopOwnerApplicants = shopSnapshot.docs.map((doc) {
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
        title: Text(_selectedIndex == 0 ? 'Driver Applicants' : 'Shop Owner Applicants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
              ? _buildDriverList()
              : _buildShopOwnerList(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 45.0),
        child: GNav(
          color: const Color(0xFF1A237E),
          activeColor: const Color(0xFFFFFFFF),
          tabBackgroundColor: const Color(0xFF1A237E),
          gap: 8,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          mainAxisAlignment: MainAxisAlignment.center,
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: const [
            GButton(
              icon: Icons.delivery_dining,
              text: "Drivers",
            ),
            GButton(
              icon: Icons.storefront,
              text: "Shop Owners",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverList() {
    if (driverApplicants.isEmpty) {
      return const Center(
        child: Text(
          "No pending driver applicants.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: driverApplicants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        var driver = driverApplicants[index];
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
            ).then((_) => _fetchAllApplicants());
          },
        );
      },
    );
  }

  Widget _buildShopOwnerList() {
    if (shopOwnerApplicants.isEmpty) {
      return const Center(
        child: Text(
          "No pending shop owner applicants.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: shopOwnerApplicants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        var owner = shopOwnerApplicants[index];
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
            ).then((_) => _fetchAllApplicants());
          },
        );
      },
    );
  }
}
