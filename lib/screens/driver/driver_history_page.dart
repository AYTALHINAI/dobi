import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../database.dart';
import 'driver_widgets.dart';

class DriverHistoryPage extends StatefulWidget {
  final String uid;
  const DriverHistoryPage({super.key, required this.uid});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  DateTime? _selectedDay;

  // Today = index 0; older dates follow. reverse:true on ListView puts index 0 on the RIGHT.
  final List<DateTime> _recentDays = List.generate(30, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - i);
  });

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<QueryDocumentSnapshot> _sorted(List<QueryDocumentSnapshot> raw) {
    return [...raw]..sort((a, b) {
        final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
        final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return (bTs as Timestamp).compareTo(aTs as Timestamp);
      });
  }

  List<QueryDocumentSnapshot> _filterByDay(
      List<QueryDocumentSnapshot> docs, DateTime? day) {
    if (day == null) return docs;
    return docs.where((doc) {
      final ts = (doc.data() as Map<String, dynamic>)['createdAt'];
      if (ts == null || ts is! Timestamp) return false;
      final d = ts.toDate();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  bool _hasDelivery(List<QueryDocumentSnapshot> docs, DateTime day) {
    return docs.any((doc) {
      final ts = (doc.data() as Map<String, dynamic>)['createdAt'];
      if (ts is! Timestamp) return false;
      final d = ts.toDate();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickFromCalendar(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black87,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getDriverOrderHistory(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black87),
          );
        }

        final allDocs  = _sorted(snapshot.data?.docs ?? []);
        final filtered = _filterByDay(allDocs, _selectedDay);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            _buildHeader(),

            // ── Date strip ────────────────────────────────────────────────────
            _buildDateStrip(allDocs),

            // ── Results label ─────────────────────────────────────────────────
            if (_selectedDay != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Text(
                      _formatDay(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filtered.length} order${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDay = null),
                      child: Text(
                        'Show all',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),

            // ── Orders list ───────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? buildDriverEmptyState(
                      icon: Icons.history_rounded,
                      title: _selectedDay != null
                          ? 'No deliveries on this day'
                          : 'No Delivery History',
                      subtitle: _selectedDay != null
                          ? 'Try selecting a different date.'
                          : 'Your completed deliveries will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final orderData =
                            filtered[index].data() as Map<String, dynamic>;
                        return DriverOrderCard(
                          orderData: orderData,
                          actionWidget: const Text(
                            'Completed ✓',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Lottie.asset(
              'assets/Delivery.json',
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
                  'Delivery History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a date below to filter your deliveries',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact horizontal date strip ─────────────────────────────────────────────

  Widget _buildDateStrip(List<QueryDocumentSnapshot> allDocs) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const weekdaysShort = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label + calendar icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Text(
                  'Recent Dates',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Calendar icon → opens full date picker for older dates
                TextButton.icon(
                  onPressed: () => _pickFromCalendar(context),
                  icon: const Icon(Icons.calendar_month_rounded,
                      size: 16, color: Colors.black87),
                  label: const Text(
                    'Pick date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable day chips
          SizedBox(
            height: 72,
            child: ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),

              itemBuilder: (context, index) {
                final day      = _recentDays[index];
                final isToday  = _isSameDay(day, DateTime.now());
                final isSelected = _selectedDay != null &&
                    _isSameDay(day, _selectedDay!);
                final hasDot   = _hasDelivery(allDocs, day);

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay =
                        isSelected ? null : day; // toggle
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black87
                          : isToday
                              ? Colors.grey.shade100
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.black87
                            : isToday
                                ? Colors.black45
                                : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdaysShort[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Colors.black87
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Orange dot = has deliveries on this day
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: hasDot ? 6 : 0,
                          height: hasDot ? 6 : 0,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.black87,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected month display strip (if picked from full calendar)
          if (_selectedDay != null &&
              !_recentDays.any((d) => _isSameDay(d, _selectedDay!)))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedDay!.day} ${months[_selectedDay!.month - 1]} ${_selectedDay!.year}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDay = null),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────────

  String _formatDay(DateTime day) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday',
    ];
    return '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }
}
