import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dday_banner.dart';
import '../../widgets/event_tile.dart';
import '../calendar/add_event_screen.dart';
import '../couple/connect_couple_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final calendar = context.watch<CalendarProvider>();

    final todayEvents = calendar.todayEvents;
    final anniversaryDate =
        auth.couple?.anniversaryDate ?? auth.currentUser?.anniversaryDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '♥ ${auth.currentUser?.nickname ?? ''}',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (!auth.isConnected)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConnectCoupleScreen(),
                ),
              ),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('커플 연결'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // Data is already real-time via stream; just a UX gesture
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // D-Day banner
              DdayBanner(anniversaryDate: anniversaryDate),

              const SizedBox(height: 20),

              // Not connected banner
              if (!auth.isConnected) _buildConnectBanner(context),

              // Today's events section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘 일정',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatToday(),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Loading / events / empty state
              if (calendar.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (todayEvents.isEmpty)
                _buildEmptyToday(context)
              else
                Column(
                  children: todayEvents
                      .map(
                        (event) => EventTile(
                          event: event,
                          currentUserUid: auth.currentUser?.uid ?? '',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEventScreen(
                                initialDate: event.date,
                                editingEvent: event.ownerUid ==
                                        auth.currentUser?.uid
                                    ? event
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '파트너와 연결해보세요!',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '커플 연결 후 일정을 공유할 수 있어요.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConnectCoupleScreen(),
              ),
            ),
            child: Text(
              '연결하기',
              style: GoogleFonts.nunito(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyToday(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '오늘은 일정이 없어요',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEventScreen(initialDate: DateTime.now()),
                ),
              ),
              child: Text(
                '+ 일정 추가',
                style: GoogleFonts.nunito(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      '', '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    const weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return '${months[now.month]} ${now.day}일 (${weekdays[now.weekday]})';
  }
}
