import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database.dart';
import 'user_booking_page.dart';

class UserCategoryPage extends StatefulWidget {
  /// Which tab to open first: 0 = Cloth Cleaning, 1 = Blanket Cleaning
  final int initialTab;

  const UserCategoryPage({super.key, this.initialTab = 0});

  @override
  State<UserCategoryPage> createState() => _UserCategoryPageState();
}

class _UserCategoryPageState extends State<UserCategoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseService();

  static const _categories = ['cloth_cleaning', 'blanket_cleaning'];
  static const _labels = ['Cloth Cleaning', 'Blanket Cleaning'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Colors.black87),
          ),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A1AE6),
          unselectedLabelColor: Colors.black45,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: const Color(0xFF1A1AE6),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Cloth Cleaning'),
            Tab(text: 'Blanket Cleaning'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ShopList(
            stream: _db.getShopsByCategoryStream(_categories[0]),
            categoryLabel: _labels[0],
          ),
          _ShopList(
            stream: _db.getShopsByCategoryStream(_categories[1]),
            categoryLabel: _labels[1],
          ),
        ],
      ),
    );
  }
}

// ── Shop list for a single category tab ───────────────────────────────────────

class _ShopList extends StatelessWidget {
  const _ShopList({required this.stream, required this.categoryLabel});
  final Stream<QuerySnapshot> stream;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A1AE6)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: Colors.black12),
                const SizedBox(height: 16),
                Text(
                  'No shops offering $categoryLabel\nservices yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final shopId = docs[index].id;
            return _ShopCard(shopId: shopId, data: data);
          },
        );
      },
    );
  }
}

// ── Individual shop card ───────────────────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shopId, required this.data});
  final String shopId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final shopName = data['shopName'] ?? 'Laundry Shop';
    final wilayat = data['wilayat'] ?? '';
    final governorate = data['governorate'] ?? '';
    final location =
        [wilayat, governorate].where((s) => s.isNotEmpty).join(', ');
    final imageUrl = data['shopImageUrl'] as String?;

    // Price range from minPrice / maxPrice fields, if present
    final minPrice = data['minPrice'];
    final maxPrice = data['maxPrice'];
    final priceRange = (minPrice != null && maxPrice != null)
        ? '${minPrice.toStringAsFixed(2)} – ${maxPrice.toStringAsFixed(2)} OMR'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Shop header row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1A1AE6).withValues(alpha: 0.08),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.store_mall_directory_outlined,
                            color: Color(0xFF1A1AE6),
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.store_mall_directory_outlined,
                          color: Color(0xFF1A1AE6),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 14),
                // Shop info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Rating badge
                          Row(
                            children: const [
                              Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFF5A623)),
                              SizedBox(width: 2),
                              Text(
                                '4.5',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF5A623),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Distance
                      Row(
                        children: [
                          Icon(Icons.directions_walk_rounded,
                              size: 13, color: Colors.black45),
                          const SizedBox(width: 4),
                          const Text(
                            'Nearby',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black45),
                          ),
                          if (priceRange != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.payments_outlined,
                                size: 13, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              priceRange,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ],
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF1A1AE6)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Action button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserBookingPage(
                        shopId: shopId,
                        shopData: data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1AE6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Shop',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
