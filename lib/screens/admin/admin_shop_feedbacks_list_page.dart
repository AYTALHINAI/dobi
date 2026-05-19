import 'package:flutter/material.dart';
import '../../database.dart';
import 'admin_shop_feedback_detail_page.dart';

class AdminShopFeedbacksListPage extends StatefulWidget {
  const AdminShopFeedbacksListPage({super.key});

  @override
  State<AdminShopFeedbacksListPage> createState() =>
      _AdminShopFeedbacksListPageState();
}

class _AdminShopFeedbacksListPageState extends State<AdminShopFeedbacksListPage> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _shops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    try {
      final list = await _db.getApprovedShopOwnersList();
      if (mounted) setState(() => _shops = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text(
          'Shop Feedbacks',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadShops,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    itemCount: _shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return _ShopFeedbackListCard(
                        shop: shop,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminShopFeedbackDetailPage(shopData: shop),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'No approved laundry shops yet.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ShopFeedbackListCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;

  const _ShopFeedbackListCard({
    required this.shop,
    required this.onTap,
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
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
