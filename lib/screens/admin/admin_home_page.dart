import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../database.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Stats grid ─────────────────────────────────────────────────
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LiveStatCard(
                        title: 'Users',
                        icon: Icons.person,
                        color: const Color(0xFF2196F3),
                        stream: db.watchTotalUsers(),
                        tooltip: 'Registered customers',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LiveStatCard(
                        title: 'Shops',
                        icon: Icons.storefront,
                        color: Colors.purple,
                        stream: db.watchTotalShopOwners(),
                        tooltip: 'Approved laundry shops',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LiveStatCard(
                        title: 'Drivers',
                        icon: Icons.delivery_dining,
                        color: Colors.orange,
                        stream: db.watchTotalDrivers(),
                        tooltip: 'Approved drivers',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Orders count
                    Expanded(
                      child: _LiveStatCard(
                        title: 'Orders',
                        icon: Icons.list_alt,
                        color: const Color(0xFF4CAF50),
                        stream: db.watchTotalOrders(),
                        tooltip: 'Total orders placed',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ── Navigation buttons ─────────────────────────────────────────
            _NavButton(
              title: 'View Shop Feedbacks',
              icon: Icons.feedback_outlined,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminShopFeedbacks),
            ),
            const SizedBox(height: 12),
            _NavButton(
              title: 'Approve Applicants',
              icon: Icons.delivery_dining,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminManageRequests),
            ),
            const SizedBox(height: 12),
            _NavButton(
              title: 'Manage All Users',
              icon: Icons.verified_user_outlined,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminApprovedMembers),
            ),

          ],
        ),
      ),
    );
  }
}

// ─── Live stat card (StreamBuilder) ──────────────────────────────────────────

class _LiveStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<int> stream;
  final String tooltip;

  const _LiveStatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final countText = snapshot.hasData
            ? snapshot.data!.toString()
            : snapshot.hasError
                ? '!'
                : '…';

        return Tooltip(
          message: tooltip,
          child: _StatCardShell(
            title: title,
            icon: icon,
            color: color,
            countText: countText,
            loading: snapshot.connectionState == ConnectionState.waiting,
          ),
        );
      },
    );
  }
}

// ─── Static stat card (for Orders until order system is live) ─────────────────

class _StaticStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String count;
  final String tooltip;

  const _StaticStatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _StatCardShell(
        title: title,
        icon: icon,
        color: color,
        countText: count,
        loading: false,
        dimmed: true,
      ),
    );
  }
}

// ─── Card shell ───────────────────────────────────────────────────────────────

class _StatCardShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String countText;
  final bool loading;
  final bool dimmed;

  const _StatCardShell({
    required this.title,
    required this.icon,
    required this.color,
    required this.countText,
    required this.loading,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = dimmed ? color.withOpacity(0.55) : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withOpacity(0.3),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 30,
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: effectiveColor,
                    ),
                  )
                : Text(
                    countText,
                    style: TextStyle(
                      color: effectiveColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav button ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
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