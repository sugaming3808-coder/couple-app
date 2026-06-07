import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DdayBanner extends StatelessWidget {
  final DateTime? anniversaryDate;
  final String label;

  const DdayBanner({
    super.key,
    required this.anniversaryDate,
    this.label = '우리가 만난 날',
  });

  int _calculateDays() {
    if (anniversaryDate == null) return 0;
    final now = DateTime.now();
    final anniversary = DateTime(
      anniversaryDate!.year,
      anniversaryDate!.month,
      anniversaryDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(anniversary).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (anniversaryDate == null) {
      return _buildPlaceholder(context);
    }

    final days = _calculateDays();
    final displayText = days >= 0 ? 'D+$days' : 'D${days}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
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
                '♥ $label',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(anniversaryDate!),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Text(
            displayText,
            style: GoogleFonts.nunito(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            '기념일을 설정해주세요',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
