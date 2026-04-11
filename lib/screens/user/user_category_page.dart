import '../../theme/user_theme.dart';
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
      backgroundColor: context.uiBackground,
      appBar: AppBar(
        backgroundColor: context.uiBackground,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.uiFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: context.uiTextPrimary),
          ),
        ),
        title: Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.uiTextPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.uiPrimary,
          unselectedLabelColor: context.uiTextSecondary,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: context.uiPrimary,
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
          return Center(child: CircularProgressIndicator(color: context.uiPrimary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: context.uiDivider),
                SizedBox(height: 16),
                Text(
                  'No shops offering $categoryLabel\nservices yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.uiTextHint,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: context.uiSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.uiDivider),
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
            padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.uiPrimary.withValues(alpha: 0.08),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.store_mall_directory_outlined,
                            color: context.uiPrimary,
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.store_mall_directory_outlined,
                          color: context.uiPrimary,
                          size: 32,
                        ),
                ),
                SizedBox(width: 14),
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.uiTextPrimary,
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
                      SizedBox(height: 6),
                      // Distance
                      Row(
                        children: [
                          Icon(Icons.directions_walk_rounded,
                              size: 13, color: context.uiTextSecondary),
                          SizedBox(width: 4),
                          Text(
                            'Nearby',
                            style: TextStyle(
                                fontSize: 12, color: context.uiTextSecondary),
                          ),
                          if (priceRange != null) ...[
                            SizedBox(width: 10),
                            Icon(Icons.payments_outlined,
                                size: 13, color: context.uiTextSecondary),
                            SizedBox(width: 4),
                            Text(
                              priceRange,
                              style: TextStyle(
                                  fontSize: 12, color: context.uiTextSecondary),
                            ),
                          ],
                        ],
                      ),
                      if (location.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: context.uiPrimary),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.uiTextSecondary,
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
          SizedBox(height: 12),
          // ── Action button ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    userPageRoute((_) => UserBookingPage(
                      shopId: shopId,
                      shopData: data,
                    )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.uiPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
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
