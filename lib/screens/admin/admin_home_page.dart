import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final DatabaseService _db = DatabaseService();
  
  int _totalUsers = 0;
  int _totalShops = 0;
  int _totalDrivers = 0;
  final int _totalOrders = 0; // Static for now
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final users = await _db.getTotalUsers();
      final shops = await _db.getTotalShopOwners();
      final drivers = await _db.getTotalDrivers();
      
      setState(() {
        _totalUsers = users;
        _totalShops = shops;
        _totalDrivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Dashboard Stats Grid
                  _buildStatsGrid(),
                  
                  const SizedBox(height: 30),
                  
                  // Navigation Buttons
                  _buildNavigationButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // First Row: Users and Shops
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'USERS',
                count: _totalUsers,
                icon: Icons.person,
                color: const Color(0xFF2196F3), // Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Shops',
                count: _totalShops,
                icon: Icons.storefront,
                color: Colors.purple, 
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second Row: Drivers and Orders
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Drivers',
                count: _totalDrivers,
                icon: Icons.delivery_dining,
                color: Colors.orange, 
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Orders',
                count: _totalOrders,
                icon: Icons.list_alt,
                color: const Color(0xFF4CAF50), // Green
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 32,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        _buildNavButton(
          title: 'Manage users & feedbacks',
          icon: Icons.person_search,
          onTap: () {
            // Placeholder - no navigation yet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon!'), duration: Duration(seconds: 2)),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          title: 'Manage drivers & requests',
          icon: Icons.delivery_dining,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.adminManageRequests);
          },
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          title: 'Manage Laundry Shops',
          icon: Icons.storefront,
          onTap: () {
            // Placeholder - no navigation yet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon!'), duration: Duration(seconds: 2)),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          title: 'View System Logs',
          icon: Icons.settings,
          onTap: () {
            // Placeholder - no navigation yet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon!'), duration: Duration(seconds: 2)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D), // Dark gray/black
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}