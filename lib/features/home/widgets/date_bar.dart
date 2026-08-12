// lib/features/home/widgets/date_bar.dart

import 'package:flutter/material.dart';
import 'package:football_live_score/config/app_colors.dart';

class DateBar extends StatefulWidget {
  final String? selectedDate;
  final ValueChanged<String?> onDateSelected;

  const DateBar({super.key, required this.selectedDate, required this.onDateSelected});

  @override
  State<DateBar> createState() => _DateBarState();
}

class _DateBarState extends State<DateBar> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  AnimationController? _pulseController;
  int? _pressedIndex;

  // ─── Fixed start date (backend data available from this date) ──
  // Using static final because DateTime constructor is not const
  static final DateTime _startDate = DateTime(2026, 5, 15);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  // ─── Scroll to today's pill ────────────────────────────────────
  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final pills = _generateDatePills();
    final todayStr = _toLocalDateStr(DateTime.now());
    final todayIndex = pills.indexWhere((p) => p.dateStr == todayStr);
    if (todayIndex == -1) return;

    // Estimate offset: width of each pill (52) + margin (5) + some padding
    const double pillWidth = 52.0;
    const double margin = 5.0;
    final double offset = (todayIndex * (pillWidth + margin)) - 40; // 40 to center partially
    final double maxExtent = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ─── Generate pills from fixed start date to today + 7 days ───
  List<_DatePill> _generateDatePills() {
    final pills = <_DatePill>[];
    final today = DateTime.now();
    final todayStr = _toLocalDateStr(today);
    final endDate = today.add(const Duration(days: 7));

    // If start date is after today, use today as start (should not happen)
    DateTime start = _startDate;
    if (start.isAfter(endDate)) start = today.subtract(const Duration(days: 7));

    DateTime current = start;
    while (!current.isAfter(endDate)) {
      final dateStr = _toLocalDateStr(current);
      pills.add(_DatePill(
        dateStr: dateStr,
        label: dateStr == todayStr ? 'TODAY' : _dayLabel(current),
        dayNum: '${current.day}',
        monthShort: _monthShort(current),
        isToday: dateStr == todayStr,
      ));
      current = current.add(const Duration(days: 1));
    }
    return pills;
  }

  String _dayLabel(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[d.weekday - 1];
  }

  String _monthShort(DateTime d) {
    const months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[d.month];
  }

  String _toLocalDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final pills = _generateDatePills();
    final isLiveMode = widget.selectedDate == null;

    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          _buildLiveButton(isLiveMode),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(width: 1, color: AppColors.border.withOpacity(0.4)),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              itemCount: pills.length,
              itemBuilder: (context, index) =>
                  _buildDatePill(pills[index], widget.selectedDate == pills[index].dateStr, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveButton(bool isLiveMode) {
    return GestureDetector(
      onTap: () => widget.onDateSelected(null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isLiveMode
              ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : null,
          color: isLiveMode ? null : AppColors.live.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLiveMode ? Colors.transparent : AppColors.live.withOpacity(0.2)),
          boxShadow: isLiveMode
              ? [BoxShadow(color: AppColors.live.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pulseController != null)
              ListenableBuilder(
                listenable: _pulseController!,
                builder: (context, child) {
                  final v = _pulseController!.value;
                  return Container(
                    width: 7 + v * 3,
                    height: 7 + v * 3,
                    decoration: BoxDecoration(
                      color: isLiveMode ? Colors.white : AppColors.live,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isLiveMode ? Colors.white : AppColors.live).withOpacity(0.4 + v * 0.3),
                          blurRadius: 4 + v * 6,
                        )
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: isLiveMode ? Colors.white : AppColors.live, shape: BoxShape.circle),
              ),
            const SizedBox(height: 5),
            Text(
              'LIVE',
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isLiveMode ? Colors.white : AppColors.live,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill(_DatePill pill, bool isActive, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedIndex = index),
        onTapUp: (_) => setState(() => _pressedIndex = null),
        onTapCancel: () => setState(() => _pressedIndex = null),
        onTap: () => widget.onDateSelected(pill.dateStr),
        child: AnimatedScale(
          scale: _pressedIndex == index ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [AppColors.accent, AppColors.accent.withOpacity(0.78)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: isActive ? null : AppColors.surface2.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? Colors.transparent : AppColors.border.withOpacity(0.4)),
              boxShadow: isActive
                  ? [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pill.label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? Colors.black87 : AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  pill.dayNum,
                  style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isActive ? Colors.black : AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  pill.monthShort,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.black54 : AppColors.textMuted2,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pill.isToday ? (isActive ? Colors.black45 : AppColors.accent) : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: pill.isToday && !isActive
                        ? [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 4)]
                        : [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Internal Data Model ──────────────────────────────────────
class _DatePill {
  final String dateStr;
  final String label;
  final String dayNum;
  final String monthShort;
  final bool isToday;

  const _DatePill({
    required this.dateStr,
    required this.label,
    required this.dayNum,
    required this.monthShort,
    required this.isToday,
  });
}