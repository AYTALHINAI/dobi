import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database.dart';
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Top bar ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DOBBIE',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1AE6),
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Cart icon with live badge
                      _CartBadgeButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserCartPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchFocus.unfocus(),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search for laundry shops…',
                      hintStyle:
                          const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.black45, size: 22),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.black38, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF4F4F6),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF1A1AE6), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

              // ── When searching: live results ─────────────────────────────────
              if (isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: const Text(
                      'Search Results',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1AE6),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: _ShopSearchResults(query: _query),
                ),
              ],

              // ── When NOT searching: regular home content ──────────────────────
              if (!isSearching) ...[
                // Nearby Shops section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: const Text(
                      'Nearby Shops',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1AE6),
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: const Text(
                      'Services Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1AE6),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            label: 'Cloth\nCleaning',
                            icon: Icons.checkroom_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const UserCategoryPage(initialTab: 0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _CategoryCard(
                            label: 'Blanket\nCleaning',
                            icon: Icons.bed_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const UserCategoryPage(initialTab: 1),
                              ),
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: const Text(
                      'Popular Services',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1AE6),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PopularServiceCard(
                            shopName: 'Gloss up Laundry',
                            rating: 4.5,
                            distance: '0.2km',
                            color: const Color(0xFFB8A98C),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _PopularServiceCard(
                            shopName: 'Gloss up Laundry',
                            rating: 4.5,
                            distance: '0.2km',
                            color: const Color(0xFFC4B49A),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          return const SizedBox(
            height: 170,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A1AE6), strokeWidth: 2),
            ),
          );
        }

        final shops = snapshot.data ?? [];

        if (shops.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1AE6).withValues(alpha: 0.06),
                    const Color(0xFF1A1AE6).withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF1A1AE6).withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1AE6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store_mall_directory_outlined,
                        color: Color(0xFF1A1AE6), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coming to your area soon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'More laundry shops will be available near your location in the future.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
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
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: shops.length,
            itemBuilder: (context, i) {
              final shop = shops[i];
              final shopId = shop['id'] as String;
              final name = shop['shopName'] ?? 'Laundry Shop';
              final wilayat = shop['wilayat'] ?? '';
              final imageUrl = shop['shopImageUrl'] as String?;
              final color = _cardColors[i % _cardColors.length];

              return Padding(
                padding: EdgeInsets.only(right: i < shops.length - 1 ? 14 : 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserBookingPage(
                        shopId: shopId,
                        shopData: shop,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background image (if any)
                        if (imageUrl != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                color: Colors.black38,
                                colorBlendMode: BlendMode.darken,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (wilayat.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 11, color: Colors.white70),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        wilayat,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
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
                        // Tap ripple indicator
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
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
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 52, color: Colors.black12),
                  const SizedBox(height: 12),
                  Text(
                    'No shops found for "$query"',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black38),
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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1AE6).withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.store_mall_directory_outlined,
                                color: Color(0xFF1A1AE6),
                                size: 26))
                        : const Icon(
                            Icons.store_mall_directory_outlined,
                            color: Color(0xFF1A1AE6),
                            size: 26,
                          ),
                  ),
                  title: Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: location.isNotEmpty
                      ? Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF1A1AE6)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.black26),
                  onTap: () {
                    final doc = filtered[index];
                    final shopData = doc.data() as Map<String, dynamic>;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserBookingPage(
                          shopId: doc.id,
                          shopData: shopData,
                        ),
                      ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: const Color(0xFF1A1AE6), size: 28),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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

// ── Popular service card ───────────────────────────────────────────────────────
class _PopularServiceCard extends StatelessWidget {
  const _PopularServiceCard({
    required this.shopName,
    required this.rating,
    required this.distance,
    required this.color,
  });

  final String shopName;
  final double rating;
  final String distance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.local_laundry_service_outlined,
                color: Colors.white38, size: 44),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFF5A623), size: 14),
            const SizedBox(width: 3),
            Text(
              rating.toString(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const Spacer(),
            Text(
              distance,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.directions_walk,
                size: 14, color: Colors.black45),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          shopName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.black87, size: 22),
          ),
          if (uid != null)
            StreamBuilder<QuerySnapshot>(
              stream: db.getCartStream(uid),
              builder: (_, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
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
