import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../database.dart';
import 'driver_widgets.dart';

// ── Oman Governorate → Wilayat map ────────────────────────────────────────────
const Map<String, List<String>> _governorateWilayatMap = {
  'Muscat': ['Muttrah', 'Bawshar', 'Seeb', 'Al Amerat', 'Qurayyat'],
  'Dhofar': ['Salalah', 'Taqah', 'Mirbat', 'Thumrait', 'Sadah', 'Rakhyut', 'Dalkut', 'Muqshin'],
  'Musandam': ['Khasab', 'Bukha', 'Dibba Al Baya', 'Madha'],
  'Al Buraimi': ['Mahdah', 'Al Sinainah'],
  'Al Dakhiliyah': ['Nizwa', 'Bahla', 'Adam', 'Izki', 'Samail', 'Bidbid', 'Manah'],
  'Al Dhahirah': ['Ibri', 'Yanqul', 'Dhank'],
  'North Al Batinah': ['Sohar', 'Shinas', 'Liwa', 'Saham', 'Al Khaburah', 'Suwaiq'],
  'South Al Batinah': ['Rustaq', 'Nakhal', 'Wadi Al Maawil', 'Barka', 'Al Musannah'],
  'North Al Sharqiyah': ['Ibra', 'Al Mudhaibi', 'Bidiyah', 'Qabil', 'Wadi Bani Khalid', 'Dema Wa Thaieen'],
  'South Al Sharqiyah': ['Sur', 'Jalan Bani Bu Ali', 'Jalan Bani Bu Hassan', 'Al Kamil Wal Wafi', 'Masirah'],
  'Al Wusta': ['Haima', 'Duqm', 'Mahout', 'Al Jazer'],
};

class DriverAvailableOrdersPage extends StatefulWidget {
  final String uid;
  const DriverAvailableOrdersPage({super.key, required this.uid});

  @override
  State<DriverAvailableOrdersPage> createState() =>
      _DriverAvailableOrdersPageState();
}

class _DriverAvailableOrdersPageState
    extends State<DriverAvailableOrdersPage> {
  String? _selectedGovernorate;
  String? _selectedWilayat;

  List<String> get _governorates => _governorateWilayatMap.keys.toList();
  List<String> get _wilayats => _selectedGovernorate != null
      ? _governorateWilayatMap[_selectedGovernorate]!
      : [];

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Client-side filter: keep only orders whose shop is in the selected area.
  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    if (_selectedGovernorate == null && _selectedWilayat == null) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final shopGov = (data['shopGovernorate'] ?? '').toString();
      final shopWil = (data['shopWilayat'] ?? '').toString();

      final govMatch = _selectedGovernorate == null ||
          shopGov.toLowerCase() == _selectedGovernorate!.toLowerCase();
      final wilMatch = _selectedWilayat == null ||
          shopWil.toLowerCase() == _selectedWilayat!.toLowerCase();

      return govMatch && wilMatch;
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Lottie header + dropdowns ─────────────────────────────────────────
        _buildHeader(),

        // ── Orders list ───────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: DatabaseService().getDriverAvailableOrders(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black87),
                );
              }

              final filtered = _filter(snapshot.data?.docs ?? []);

              if (filtered.isEmpty) {
                return buildDriverEmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'No Available Orders',
                  subtitle: _selectedGovernorate != null
                      ? 'No orders in the selected area yet.'
                      : 'Wait for shops to prepare orders.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final orderDoc  = filtered[index];
                  final orderData = orderDoc.data() as Map<String, dynamic>;

                  return DriverOrderCard(
                    orderData: orderData,
                    actionWidget: ElevatedButton(
                      onPressed: () async {
                        await DatabaseService()
                            .assignDriverToOrder(orderDoc.id, widget.uid);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept Order'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Header widget ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lottie animation + title row
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Lottie.asset(
                  'assets/Globe.json',
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Filter by shop location to find nearby pickups',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Governorate dropdown
          _buildDropdown(
            value: _selectedGovernorate,
            hint: 'All Governorates',
            icon: Icons.map_rounded,
            items: _governorates,
            onChanged: (val) => setState(() {
              _selectedGovernorate = val;
              _selectedWilayat = null;
            }),
            onClear: _selectedGovernorate != null
                ? () => setState(() {
                      _selectedGovernorate = null;
                      _selectedWilayat = null;
                    })
                : null,
          ),

          const SizedBox(height: 10),

          // Wilayat dropdown (dependent)
          _buildDropdown(
            value: _selectedWilayat,
            hint: _selectedGovernorate == null
                ? 'Select Governorate First'
                : 'All Wilayats',
            icon: Icons.location_city_rounded,
            items: _wilayats,
            enabled: _selectedGovernorate != null,
            onChanged: _selectedGovernorate == null
                ? null
                : (val) => setState(() => _selectedWilayat = val),
            onClear: _selectedWilayat != null
                ? () => setState(() => _selectedWilayat = null)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Dropdown builder ──────────────────────────────────────────────────────────

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: onClear != null && value != null
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
          hint: Row(
            children: [
              Icon(icon,
                  color: enabled
                      ? const Color(0xFF5C6BC0)
                      : Colors.grey.shade400,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                hint,
                style: TextStyle(
                  color: enabled
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          selectedItemBuilder: (context) => items
              .map((item) => Row(
                    children: [
                      Icon(icon,
                          color: const Color(0xFF5C6BC0), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ))
              .toList(),
          items: enabled
              ? items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList()
              : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
