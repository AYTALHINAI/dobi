import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database.dart';
import '../../theme/user_theme.dart';
import 'user_category_page.dart';
import 'user_booking_page.dart';
import 'user_cart_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dismiss the keyboard whenever this page (re)gains visibility —
    // e.g. returning from another tab or navigating back from a sub-route.
    _searchFocus.unfocus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _query.isNotEmpty;

    return GestureDetector(
      // Dismiss the keyboard / search focus when tapping anywhere
      onTap: () => _searchFocus.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: context.uiBackground,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Top bar ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Image.asset('assets/logo_horizon.png'
                            ,width:150 , height: 60,
                          ),
                      // Cart icon with live badge
                      _CartBadgeButton(
                        onTap: () => Navigator.push(
                          context,
                          userPageRoute((_) => const UserCartPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchFocus.unfocus(),
                    style: TextStyle(fontSize: 14, color: context.uiTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search for laundry shops…',
                      hintStyle: TextStyle(color: context.uiTextHint, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: context.uiIcon, size: 22),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  color: context.uiTextHint, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.uiFill,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: context.uiPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

              // ── When searching: live results ─────────────────────────────────
              if (isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text(
                      'Search Results',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.uiPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: _ShopSearchResults(query: _query),
                ),
              ],

              // ── When NOT searching: regular home content ──────────────────────
              if (!isSearching) ...[
                // Nearby Shops section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(
                      'Nearby Shops',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.uiPrimary,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _NearbyShopsSection(),
                ),

                // Services Categories
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(
                      'Services Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.uiPrimary,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            label: 'Cloth\nCleaning',
                            icon: Icons.checkroom_outlined,
                            onTap: () => Navigator.push(
                              context,
                              userPageRoute((_) =>
                                  const UserCategoryPage(initialTab: 0)),
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _CategoryCard(
                            label: 'Blanket\nCleaning',
                            icon: Icons.bed_outlined,
                            onTap: () => Navigator.push(
                              context,
                              userPageRoute((_) =>
                                  const UserCategoryPage(initialTab: 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Popular Services
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text(
                      'Popular Services',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.uiPrimary,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: const _PopularServicesSection(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ── Nearby shops section (real data from Firestore) ───────────────────────────
class _NearbyShopsSection extends StatefulWidget {
  const _NearbyShopsSection();

  @override
  State<_NearbyShopsSection> createState() => _NearbyShopsSectionState();
}

class _NearbyShopsSectionState extends State<_NearbyShopsSection> {
  final _db = DatabaseService();
  late final Future<List<Map<String, dynamic>>> _future;

  static const List<Color> _cardColors = [
    Color(0xFF1F3A6E),
    Color(0xFF2C6B3F),
    Color(0xFF5C3A8E),
    Color(0xFF8E3A3A),
    Color(0xFF2C617A),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadNearbyShops();
  }

  Future<List<Map<String, dynamic>>> _loadNearbyShops() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    // Get user's wilayat
    String? userWilayat;
    try {
      final userDoc = await _db.getUserDoc(uid);
      if (userDoc.exists) {
        final data = userDoc.data()! as Map<String, dynamic>;
        userWilayat = (data['wilayat'] as String?)?.trim();
      }
    } catch (_) {}

    if (userWilayat == null || userWilayat.isEmpty) return [];

    // Fetch approved shops in the same wilayat
    final snap = await _db.getApprovedShopsStream().first;
    final matching = snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .where((d) =>
            (d['wilayat'] as String?)?.toLowerCase().trim() ==
            userWilayat!.toLowerCase())
        .toList();

    // Shuffle and take up to 3
    matching.shuffle(Random());
    return matching.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 170,
            child: Center(
              child: CircularProgressIndicator(
                color: context.uiPrimary, strokeWidth: 2),
            ),
          );
        }

        final shops = snapshot.data ?? [];

        if (shops.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.uiPrimary.withValues(alpha: 0.06),
                    context.uiPrimary.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: context.uiPrimary.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.uiPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store_mall_directory_outlined,
                        color: context.uiPrimary, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coming to your area soon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.uiTextPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'More laundry shops will be available near your location in the future.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.uiTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: shops.length,
            itemBuilder: (context, i) {
              final shop = shops[i];
              final shopId = shop['id'] as String;
              final name = shop['shopName'] ?? 'Laundry Shop';
              final imageUrl = shop['shopImageUrl'] as String?;
              final color = _cardColors[i % _cardColors.length];

              return Padding(
                padding: EdgeInsets.only(right: i < shops.length - 1 ? 16 : 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    userPageRoute((_) => UserBookingPage(
                      shopId: shopId,
                      shopData: shop,
                    )),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: context.uiPrimary.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.store_mall_directory_outlined,
                                      color: Colors.white, size: 28),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.store_mall_directory_outlined,
                                    color: Colors.white, size: 28),
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 76,
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.uiTextPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Live search results sliver ─────────────────────────────────────────────────
class _ShopSearchResults extends StatelessWidget {
  const _ShopSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.toLowerCase();
    final db = DatabaseService();

    return StreamBuilder<QuerySnapshot>(
      stream: db.getApprovedShopsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Client-side filter: match shopName or wilayat or governorate
        final filtered = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final shopName = (data['shopName'] ?? '').toString().toLowerCase();
          final wilayat = (data['wilayat'] ?? '').toString().toLowerCase();
          final governorate =
              (data['governorate'] ?? '').toString().toLowerCase();
          return shopName.contains(lowerQuery) ||
              wilayat.contains(lowerQuery) ||
              governorate.contains(lowerQuery);
        }).toList();

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 52, color: context.uiTextHint),
                  SizedBox(height: 12),
                  Text(
                    'No shops found for "$query"',
                    style: TextStyle(
                        fontSize: 14, color: context.uiTextSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data =
                  filtered[index].data() as Map<String, dynamic>;
              final shopName = data['shopName'] ?? 'Laundry Shop';
              final wilayat = data['wilayat'] ?? '';
              final governorate = data['governorate'] ?? '';
              final location = [wilayat, governorate]
                  .where((s) => s.isNotEmpty)
                  .join(', ');
              final imageUrl = data['shopImageUrl'] as String?;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: context.uiSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.uiDivider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.uiPrimary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.store_mall_directory_outlined,
                                color: context.uiPrimary,
                                size: 26))
                        : Icon(
                            Icons.store_mall_directory_outlined,
                            color: context.uiPrimary,
                            size: 26,
                          ),
                  ),
                  title: Text(
                    shopName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.uiTextPrimary,
                    ),
                  ),
                  subtitle: location.isNotEmpty
                      ? Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: context.uiPrimary),
                            SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                location,
                                style: TextStyle(
                                    fontSize: 12, color: context.uiTextSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: context.uiTextHint),
                  onTap: () {
                    final doc = filtered[index];
                    final shopData = doc.data() as Map<String, dynamic>;
                    Navigator.push(
                      context,
                      userPageRoute((_) => UserBookingPage(
                        shopId: doc.id,
                        shopData: shopData,
                      )),
                    );
                  },
                ),
              );
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }
}

// ── Category card ──────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: context.uiSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.uiDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -8,
              child: Icon(icon,
                  color: Colors.black.withValues(alpha: 0.06), size: 80),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: context.uiPrimary, size: 28),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.uiTextPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popular service section & card ──────────────────────────────────────────────
class _PopularServicesSection extends StatefulWidget {
  const _PopularServicesSection();

  @override
  State<_PopularServicesSection> createState() => _PopularServicesSectionState();
}

class _PopularServicesSectionState extends State<_PopularServicesSection> {
  final _db = DatabaseService();
  late final Future<List<Map<String, dynamic>>> _future;

  static const List<Color> _cardColors = [
    Color(0xFF2C6B3F),
    Color(0xFF1F3A6E),
    Color(0xFF8E3A3A),
    Color(0xFF5C3A8E),
    Color(0xFF2C617A),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadPopularShops();
  }

  Future<List<Map<String, dynamic>>> _loadPopularShops() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    String? userWilayat;
    try {
      final userDoc = await _db.getUserDoc(uid);
      if (userDoc.exists) {
        final data = userDoc.data()! as Map<String, dynamic>;
        userWilayat = (data['wilayat'] as String?)?.trim();
      }
    } catch (_) {}

    if (userWilayat == null || userWilayat.isEmpty) return [];

    final snap = await _db.getApprovedShopsStream().first;
    final matching = snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .where((d) =>
            (d['wilayat'] as String?)?.toLowerCase().trim() ==
            userWilayat!.toLowerCase())
        .toList();

    List<Map<String, dynamic>> ratedShops = [];
    for (var shop in matching) {
      final rating = await _db.getShopAverageRatingFuture(shop['id']);
      if (rating > 0) {
        shop['averageRating'] = rating;
        ratedShops.add(shop);
      }
    }

    ratedShops.sort((a, b) => (b['averageRating'] as double).compareTo(a['averageRating'] as double));

    return ratedShops.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No popular shops available yet in your area',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              final shopId = shop['id'] as String;
              final shopName = shop['shopName'] ?? 'Unknown Shop';
              final wilayat = shop['wilayat'] ?? '';
              final imageUrl = shop['shopImageUrl'] as String?;
              final rating = shop['averageRating'] as double;
              final color = _cardColors[index % _cardColors.length];

              return Padding(
                padding: EdgeInsets.only(right: index < shops.length - 1 ? 16 : 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      userPageRoute((_) => UserBookingPage(
                            shopId: shopId,
                            shopData: shop,
                          )),
                    );
                  },
                  child: _PopularServiceCard(
                    shopId: shopId,
                    shopName: shopName,
                    wilayat: wilayat,
                    rating: rating,
                    color: color,
                    imageUrl: imageUrl,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PopularServiceCard extends StatelessWidget {
  const _PopularServiceCard({
    required this.shopId,
    required this.shopName,
    required this.wilayat,
    required this.rating,
    required this.color,
    this.imageUrl,
  });

  final String shopId;
  final String shopName;
  final String wilayat;
  final double rating;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        wilayat,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart badge icon button ─────────────────────────────────────────────────────
class _CartBadgeButton extends StatelessWidget {
  const _CartBadgeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final db = DatabaseService();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.uiSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.shopping_cart_outlined,
                color: context.uiTextPrimary, size: 22),
          ),
          if (uid != null)
            StreamBuilder<QuerySnapshot>(
              stream: db.getCartStream(uid),
              builder: (_, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return SizedBox.shrink();
                return Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
