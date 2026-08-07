import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class DateSelectionScreen extends HookWidget {
  const DateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedStartDate = useState<DateTime?>(null);
    final selectedEndDate = useState<DateTime?>(null);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              selectedStartDate.value = null;
              selectedEndDate.value = null;
            },
            child: Text(
              'Reset',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select dates',
                  style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your travel dates for exact pricing',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // Check-in / Check-out Cards
                Row(
                  children: [
                    Expanded(
                      child: _DateInfoCard(
                        label: 'CHECK-IN',
                        date: selectedStartDate.value,
                        isSelected: selectedStartDate.value != null && selectedEndDate.value == null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateInfoCard(
                        label: 'CHECK-OUT',
                        date: selectedEndDate.value,
                        isSelected: selectedEndDate.value != null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar Controls (Dates / Months / Flexible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.sectionColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                   _TabItem(title: 'Dates', isSelected: true),
                   _TabItem(title: 'Months', isSelected: false),
                   _TabItem(title: 'Flexible', isSelected: false),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Calendar
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 12, // Show next 12 months
              itemBuilder: (context, index) {
                final month = DateTime(DateTime.now().year, DateTime.now().month + index, 1);
                return _MonthCalendar(
                  month: month,
                  selectedStartDate: selectedStartDate.value,
                  selectedEndDate: selectedEndDate.value,
                  onDateTap: (date) {
                    if (selectedStartDate.value == null || (selectedStartDate.value != null && selectedEndDate.value != null)) {
                      selectedStartDate.value = date;
                      selectedEndDate.value = null;
                    } else if (date.isBefore(selectedStartDate.value!)) {
                      selectedStartDate.value = date;
                    } else if (date.isAtSameMomentAs(selectedStartDate.value!)) {
                       // Do nothing or toggle
                    } else {
                      selectedEndDate.value = date;
                    }
                  },
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedStartDate.value != null && selectedEndDate.value != null
                          ? '${DateFormat('MMM d').format(selectedStartDate.value!)} - ${DateFormat('MMM d').format(selectedEndDate.value!)}'
                          : 'No dates selected',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (selectedStartDate.value != null && selectedEndDate.value != null)
                      Text(
                        '${selectedEndDate.value!.difference(selectedStartDate.value!).inDays} nights',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                  ],
                ),
                ElevatedButton(
                  onPressed: selectedStartDate.value != null && selectedEndDate.value != null
                      ? () => context.pop({
                            'start': selectedStartDate.value,
                            'end': selectedEndDate.value,
                          })
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(120, 48),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  const _TabItem({required this.title, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DateInfoCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isSelected;

  const _DateInfoCard({
    required this.label,
    this.date,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : AppTheme.sectionColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.textPrimary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isSelected ? AppTheme.surfaceShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date != null ? DateFormat('MMM d, y').format(date!) : 'Add date',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final Function(DateTime) onDateTap;

  const _MonthCalendar({
    required this.month,
    this.selectedStartDate,
    this.selectedEndDate,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday % 7;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
          child: Text(
            DateFormat('MMMM y').format(month),
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Weekday labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day.substring(0, 1),
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Days grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: daysInMonth + firstDayOffset,
          itemBuilder: (context, index) {
            if (index < firstDayOffset) return const SizedBox.shrink();
            
            final day = index - firstDayOffset + 1;
            final date = DateTime(month.year, month.month, day);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 0))) && !isToday;
            
            bool isStart = selectedStartDate != null && DateUtils.isSameDay(date, selectedStartDate!);
            bool isEnd = selectedEndDate != null && DateUtils.isSameDay(date, selectedEndDate!);
            bool isInRange = selectedStartDate != null && 
                            selectedEndDate != null && 
                            date.isAfter(selectedStartDate!) && 
                            date.isBefore(selectedEndDate!);

            return GestureDetector(
              onTap: isPast ? null : () => onDateTap(date),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isInRange)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sectionColor,
                      ),
                    ),
                  if (isStart)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 25,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: selectedEndDate != null ? AppTheme.sectionColor : Colors.transparent,
                        ),
                      ),
                    ),
                  if (isEnd)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 25,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sectionColor,
                        ),
                      ),
                    ),
                  if (isStart || isEnd)
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isStart && !isEnd)
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: AppTheme.primaryColor, width: 1)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isPast ? Colors.grey.shade300 : AppTheme.textPrimary,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
