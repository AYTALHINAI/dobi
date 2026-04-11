import 'package:flutter/material.dart';
import '../../database.dart';
import 'admin_approved_shop_detail_page.dart';
import 'admin_approved_driver_detail_page.dart';

class AdminApprovedMembersPage extends StatefulWidget {
  const AdminApprovedMembersPage({super.key});

  @override
  State<AdminApprovedMembersPage> createState() =>
      _AdminApprovedMembersPageState();
}

class _AdminApprovedMembersPageState extends State<AdminApprovedMembersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DatabaseService _db = DatabaseService();

  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _loadingShops = true;
  bool _loadingDrivers = true;

  static const Color _primary = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShops();
    _loadDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _loadingShops = true);
    try {
      final list = await _db.getApprovedShopOwnersList();
      if (mounted) setState(() => _shops = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingShops = false);
    }
  }

  Future<void> _loadDrivers() async {
    setState(() => _loadingDrivers = true);
    try {
      final list = await _db.getApprovedDriversList();
      if (mounted) setState(() => _drivers = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  // ── Delete helpers ──────────────────────────────────────────────────────────

  Future<void> _confirmDeleteShop(Map<String, dynamic> shop) async {
    final confirmed = await _showDeleteDialog(
      name: shop['shopName'] ?? shop['ownerName'] ?? 'this shop',
    );
    if (!confirmed || !mounted) return;

    try {
      await _db.deleteShopOwner(shop['uid'] as String);
      if (mounted) {
        setState(() => _shops.removeWhere((s) => s['uid'] == shop['uid']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop deleted successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteDriver(Map<String, dynamic> driver) async {
    final confirmed = await _showDeleteDialog(
      name: driver['fullName'] ?? 'this driver',
    );
    if (!confirmed || !mounted) return;

    try {
      await _db.deleteDriver(driver['uid'] as String);
      if (mounted) {
        setState(() =>
            _drivers.removeWhere((d) => d['uid'] == driver['uid']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver deleted successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog({required String name}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text(
              'Confirm Deletion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$name"?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Approved Members',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.storefront_outlined),
              text: 'Laundry Shops (${_shops.length})',
            ),
            Tab(
              icon: const Icon(Icons.delivery_dining_outlined),
              text: 'Drivers (${_drivers.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopsTab(),
          _buildDriversTab(),
        ],
      ),
    );
  }

  // ── Shops tab ────────────────────────────────────────────────────────────────

  Widget _buildShopsTab() {
    if (_loadingShops) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_shops.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_outlined,
        message: 'No approved laundry shops yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShops,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: _shops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final shop = _shops[index];
          return _ShopCard(
            shop: shop,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminApprovedShopDetailPage(shopData: shop),
                ),
              );
              _loadShops();
            },
            onDelete: () => _confirmDeleteShop(shop),
          );
        },
      ),
    );
  }

  // ── Drivers tab ──────────────────────────────────────────────────────────────

  Widget _buildDriversTab() {
    if (_loadingDrivers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_drivers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.delivery_dining_outlined,
        message: 'No approved drivers yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: _drivers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return _DriverCard(
            driver: driver,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminApprovedDriverDetailPage(driverData: driver),
                ),
              );
              _loadDrivers();
            },
            onDelete: () => _confirmDeleteDriver(driver),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Shop card ────────────────────────────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ShopCard({
    required this.shop,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        ((shop['shopName'] as String?) ?? 'S')[0].toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.purple.shade50,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop['shopName'] ?? 'No Shop Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop['ownerName'] ?? '',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shop['governorate'] ?? ''}  •  ${shop['wilayat'] ?? ''}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                tooltip: 'Delete shop',
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Driver card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DriverCard({
    required this.driver,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        ((driver['fullName'] as String?) ?? 'D')[0].toUpperCase();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange.shade50,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['fullName'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      driver['email'] ?? '',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver['vehicleType'] ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                tooltip: 'Delete driver',
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
