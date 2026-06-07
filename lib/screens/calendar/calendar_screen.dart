import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_tile.dart';
import 'add_event_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final calendar = context.watch<CalendarProvider>();

    if (!auth.isConnected) {
      return _buildNotConnected(context);
    }

    final selectedDayEvents = calendar.getEventsForDay(calendar.selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _navigateToAddEvent(context, calendar.selectedDay),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget
          Container(
            color: AppColors.white,
            child: TableCalendar<EventModel>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: calendar.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(calendar.selectedDay, day),
              eventLoader: (day) => calendar.getEventsForDay(day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              onDaySelected: (selected, focused) {
                calendar.setSelectedDay(selected);
                calendar.setFocusedDay(focused);
              },
              onPageChanged: (focusedDay) {
                calendar.setFocusedDay(focusedDay);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.nunito(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.nunito(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
                defaultTextStyle: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                ),
                weekendTextStyle: GoogleFonts.nunito(
                  color: AppColors.secondary,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                weekendStyle: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return _buildEventMarkers(events);
                },
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.divider),

          // Selected day label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSelectedDate(calendar.selectedDay),
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${selectedDayEvents.length}개',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: calendar.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : selectedDayEvents.isEmpty
                    ? _buildEmptyDay()
                    : ListView.builder(
                        itemCount: selectedDayEvents.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final event = selectedDayEvents[index];
                          return EventTile(
                            event: event,
                            currentUserUid:
                                auth.currentUser?.uid ?? '',
                            onTap: () => _navigateToEditEvent(context, event),
                            onDelete: () =>
                                _confirmDelete(context, event),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMarkers(List<EventModel> events) {
    // Show up to 3 colored dots
    final markers = events.take(3).map((e) => e.color.color).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: markers
          .map(
            (color) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: AppColors.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '이 날은 일정이 없어요',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnected(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('캘린더')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '커플 연결이 필요합니다',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  void _navigateToAddEvent(BuildContext context, DateTime date) {
    final auth = context.read<app_auth.AuthProvider>();
    if (!auth.isConnected) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventScreen(initialDate: date),
      ),
    );
  }

  void _navigateToEditEvent(BuildContext context, EventModel event) {
    final auth = context.read<app_auth.AuthProvider>();
    if (event.ownerUid != auth.currentUser?.uid) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventScreen(
          initialDate: event.date,
          editingEvent: event,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '일정 삭제',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${event.title}" 일정을 삭제할까요?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '취소',
              style: GoogleFonts.nunito(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final calendar = context.read<CalendarProvider>();
              await calendar.deleteEvent(event.id);
            },
            child: Text(
              '삭제',
              style: GoogleFonts.nunito(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
