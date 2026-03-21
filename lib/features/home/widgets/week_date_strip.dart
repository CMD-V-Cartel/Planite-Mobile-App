import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekDateStrip extends StatefulWidget {
  const WeekDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<WeekDateStrip> createState() => _WeekDateStripState();
}

class _WeekDateStripState extends State<WeekDateStrip> {
  late ScrollController _scrollController;

  static const double _itemWidth = 48;
  static const double _separatorWidth = 10;
  static const double _horizontalPadding = 16;

  List<DateTime> _daysInMonth(DateTime ref) {
    final int year = ref.year;
    final int month = ref.month;
    final int count = DateUtils.getDaysInMonth(year, month);
    return List<DateTime>.generate(
      count,
      (int i) => DateTime(year, month, i + 1),
    );
  }

  void _scrollToSelected() {
    final int dayIndex = widget.selectedDate.day - 1;
    final double offset =
        dayIndex * (_itemWidth + _separatorWidth) - _horizontalPadding;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final int dayIndex = widget.selectedDate.day - 1;
    final double initialOffset =
        dayIndex * (_itemWidth + _separatorWidth) - _horizontalPadding;
    _scrollController = ScrollController(
      initialScrollOffset: initialOffset.clamp(0.0, double.infinity),
    );
  }

  @override
  void didUpdateWidget(covariant WeekDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _daysInMonth(widget.selectedDate);

    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: 10,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => SizedBox(width: _separatorWidth),
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = days[index];
          final bool isSelected = DateUtils.isSameDay(day, widget.selectedDate);
          final bool isToday = DateUtils.isSameDay(day, DateTime.now());

          final String dow = DateFormat('EEE').format(day);
          final String dom = '${day.day}';

          return GestureDetector(
            onTap: () => widget.onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _itemWidth,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3D5AFE)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3D5AFE)
                      : const Color(0xFFE6E8EE),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    dow,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF8E95A4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dom,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? const Color(0xFF3D5AFE)
                              : const Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
