import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database.dart';
import 'shopOwner_orders_page.dart';
import 'shopOwner_profile_page.dart';
import 'shopOwner_services_page.dart';
import 'add_laundry_service_page.dart';
import 'shopOwner_feedback_page.dart';

class ShopOwnerHomePage extends StatefulWidget {
  const ShopOwnerHomePage({super.key});
  @override
  State<ShopOwnerHomePage> createState() => _ShopOwnerHomePageState();
}

class _ShopOwnerHomePageState extends State<ShopOwnerHomePage> {
  int _selectedIndex = 0;
  String _shopName = '';
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await _db.getShopOwnerDoc(uid);
      if (doc.exists && mounted) {
        setState(() {
          _shopName = (doc.data() as Map<String, dynamic>?)?['shopName'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardBody(shopName: _shopName),
      const AddLaundryServicePage(),
      const ShopOwnerProfilePage(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            activeIcon: Icon(Icons.dashboard_customize),
            label: 'Manage',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Service'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final String shopName;
  const _DashboardBody({required this.shopName});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopName.isEmpty ? 'Hello!' : 'Hello $shopName 👋',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text('Here\'s how your shop is performing',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 24),

            // Orders + Customers live stream
            if (uid != null)
              StreamBuilder<QuerySnapshot>(
                stream: DatabaseService().getShopOrdersStream(uid),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  final loading = snap.connectionState == ConnectionState.waiting;
                  final orderCount = docs.length;
                  final uniqueCustomers = docs
                      .map((d) => (d.data() as Map<String, dynamic>)['userId'] as String? ?? '')
                      .toSet()
                      .where((s) => s.isNotEmpty)
                      .length;
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Orders',
                          value: loading ? '…' : '$orderCount',
                          color: const Color(0xFF7B7FD4),
                          icon: Icons.list_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          label: 'Customers',
                          value: loading ? '…' : '$uniqueCustomers',
                          color: const Color(0xFFF5A623),
                          icon: Icons.people_alt_rounded,
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Row(children: [
                Expanded(child: _StatCard(label: 'Orders', value: '—', color: const Color(0xFF7B7FD4), icon: Icons.list_alt_rounded)),
                const SizedBox(width: 14),
                Expanded(child: _StatCard(label: 'Customers', value: '—', color: const Color(0xFFF5A623), icon: Icons.people_alt_rounded)),
              ]),

            const SizedBox(height: 14),

            // Rating live stream
            if (uid != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedback')
                    .where('shopId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _RateCard(rate: 0, value: '…');
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return const _RateCard(rate: 0, value: 'No ratings yet');
                  final total = docs.fold<double>(0, (s, d) {
                    final r = (d.data() as Map<String, dynamic>)['rating'] as num? ?? 0;
                    return s + r.toDouble();
                  });
                  final avg = total / docs.length;
                  return _RateCard(
                    rate: avg.round(),
                    value: '${avg.toStringAsFixed(1)} / 5',
                    reviewCount: docs.length,
                  );
                },
              )
            else
              const _RateCard(rate: 0, value: '—'),

            const SizedBox(height: 36),

            _ActionButton(
              icon: Icons.thumb_up_alt_outlined,
              label: 'View Feedback',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopOwnerFeedbackPage())),
            ),
            const SizedBox(height: 14),
            _ActionButton(
              icon: Icons.settings_outlined,
              label: 'View Services',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopOwnerServicesPage())),
            ),
            const SizedBox(height: 14),
            _ActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'View Orders',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopOwnerOrdersPage())),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 44),
          ),
        ],
      ),
    );
  }
}

// ─── Rate Card ─────────────────────────────────────────────────────────────────

class _RateCard extends StatelessWidget {
  final int rate;
  final String value;
  final int reviewCount;

  const _RateCard({required this.rate, required this.value, this.reviewCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFFE05555), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Rating',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              ...List.generate(
                5,
                (i) => Icon(i < rate ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF5C518), size: 18),
              ),
              if (reviewCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
