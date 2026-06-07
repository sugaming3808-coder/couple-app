import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../theme/app_theme.dart';

class ConnectCoupleScreen extends StatefulWidget {
  const ConnectCoupleScreen({super.key});

  @override
  State<ConnectCoupleScreen> createState() => _ConnectCoupleScreenState();
}

class _ConnectCoupleScreenState extends State<ConnectCoupleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeInputController = TextEditingController();
  DateTime? _selectedAnniversary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ensureCoupleCode();
  }

  Future<void> _ensureCoupleCode() async {
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.couple == null) {
      await auth.createCoupleCode();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeInputController.dispose();
    super.dispose();
  }

  Future<void> _pickAnniversary() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedAnniversary ?? DateTime.now(),
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
    if (date != null) {
      setState(() => _selectedAnniversary = date);
    }
  }

  Future<void> _connectWithCode() async {
    final code = _codeInputController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6자리 코드를 입력해주세요.')),
      );
      return;
    }
    if (_selectedAnniversary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기념일을 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<app_auth.AuthProvider>();
    final error = await auth.connectWithCode(
      code: code,
      anniversaryDate: _selectedAnniversary!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('커플 연결이 완료됐어요! ♥'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커플 연결')),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: '내 코드 공유'),
                Tab(text: '코드 입력'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyCodeTab(),
                _buildEnterCodeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodeTab() {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        final code = auth.couple?.coupleCode ?? '------';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '나의 연결 코드',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      code,
                      style: GoogleFonts.nunito(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('코드가 복사됐어요!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('코드 복사'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '이 코드를 파트너에게 공유하면\n커플 연결이 완료됩니다.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnterCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            '파트너의 코드를\n입력해주세요',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          // Code input
          TextFormField(
            controller: _codeInputController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: AppColors.primary,
            ),
            decoration: const InputDecoration(
              hintText: 'XXXXXX',
              counterText: '',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
          ),
          const SizedBox(height: 24),

          // Anniversary date picker
          Text(
            '기념일 선택',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickAnniversary,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedAnniversary != null
                      ? AppColors.primary
                      : AppColors.divider,
                  width: _selectedAnniversary != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _selectedAnniversary != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedAnniversary != null
                        ? '${_selectedAnniversary!.year}.${_selectedAnniversary!.month.toString().padLeft(2, '0')}.${_selectedAnniversary!.day.toString().padLeft(2, '0')}'
                        : '기념일을 선택해주세요',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: _selectedAnniversary != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _connectWithCode,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('커플 연결하기 ♥'),
            ),
          ),
        ],
      ),
    );
  }
}
