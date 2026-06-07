import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../theme/app_theme.dart';
import '../couple/connect_couple_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final user = auth.currentUser;
    final couple = auth.couple;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('프로필')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.nickname.isNotEmpty == true
                            ? user!.nickname[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nickname ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Couple status section
            _SectionCard(
              title: '커플 정보',
              children: [
                if (auth.couple?.isComplete != true) ...[
                  _ProfileTile(
                    icon: Icons.favorite_border_rounded,
                    iconColor: AppColors.primary,
                    title: '커플 연결',
                    subtitle: '파트너와 연결되어 있지 않아요',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectCoupleScreen(),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  _ProfileTile(
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.primary,
                    title: '연결 상태',
                    subtitle: '파트너와 연결되어 있어요 ♥',
                    onTap: null,
                  ),
                  if (couple?.anniversaryDate != null)
                    _ProfileTile(
                      icon: Icons.cake_rounded,
                      iconColor: AppColors.secondary,
                      title: '기념일',
                      subtitle: _formatDate(couple!.anniversaryDate!),
                      onTap: () => _changeAnniversary(context, auth),
                      trailing: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    _ProfileTile(
                      icon: Icons.cake_outlined,
                      iconColor: AppColors.secondary,
                      title: '기념일 설정',
                      subtitle: '기념일을 설정해주세요',
                      onTap: () => _changeAnniversary(context, auth),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (couple?.coupleCode != null)
                    _ProfileTile(
                      icon: Icons.tag_rounded,
                      iconColor: AppColors.primary,
                      title: '내 연결 코드',
                      subtitle: couple!.coupleCode,
                      onTap: null,
                    ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // App info section
            _SectionCard(
              title: '앱 정보',
              children: [
                _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  title: '버전',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Account section
            _SectionCard(
              title: '계정',
              children: [
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: '로그아웃',
                  subtitle: null,
                  titleColor: AppColors.error,
                  onTap: () => _confirmSignOut(context, auth),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _changeAnniversary(
      BuildContext context, app_auth.AuthProvider auth) async {
    final date = await showDatePicker(
      context: context,
      initialDate: auth.couple?.anniversaryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    final error = await auth.updateAnniversary(date);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _confirmSignOut(
      BuildContext context, app_auth.AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '로그아웃',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '정말 로그아웃 하시겠어요?',
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
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            child: Text(
              '로그아웃',
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
