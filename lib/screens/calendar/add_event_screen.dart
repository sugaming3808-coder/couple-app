import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime initialDate;
  final EventModel? editingEvent;

  const AddEventScreen({
    super.key,
    required this.initialDate,
    this.editingEvent,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  EventColor _eventColor = EventColor.personalA;
  bool _isShared = false;
  bool _isLoading = false;

  bool get _isEditing => widget.editingEvent != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_isEditing) {
      final e = widget.editingEvent!;
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _selectedDate = e.date;
      _eventColor = e.color;
      _isShared = e.isShared;
      if (e.startTime != null) {
        final parts = e.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (e.endTime != null) {
        final parts = e.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _startTime = time);
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
    );
    if (time != null) setState(() => _endTime = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<app_auth.AuthProvider>();
    final calendarProvider = context.read<CalendarProvider>();

    final uid = auth.currentUser?.uid;
    final coupleId = auth.currentUser?.coupleId;

    if (uid == null || coupleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커플 연결이 필요합니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final event = EventModel(
      id: _isEditing ? widget.editingEvent!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      startTime: _startTime != null ? _formatTime(_startTime!) : null,
      endTime: _endTime != null ? _formatTime(_endTime!) : null,
      ownerUid: uid,
      coupleId: coupleId,
      color: _isShared ? EventColor.shared : _eventColor,
      isShared: _isShared,
      createdAt: _isEditing ? widget.editingEvent!.createdAt : DateTime.now(),
    );

    bool success;
    if (_isEditing) {
      success = await calendarProvider.updateEvent(event);
    } else {
      success = await calendarProvider.addEvent(event);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(calendarProvider.errorMessage ?? '저장에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일정 수정' : '일정 추가'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              '저장',
              style: GoogleFonts.nunito(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '제목',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Date picker
              _SectionLabel(label: '날짜'),
              const SizedBox(height: 8),
              _PickerButton(
                icon: Icons.calendar_month_rounded,
                text:
                    '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),

              // Time picker
              _SectionLabel(label: '시간 (선택)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_rounded,
                      text: _startTime != null
                          ? _formatTime(_startTime!)
                          : '시작 시간',
                      onTap: _pickStartTime,
                      isSelected: _startTime != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_filled_rounded,
                      text: _endTime != null ? _formatTime(_endTime!) : '종료 시간',
                      onTap: _pickEndTime,
                      isSelected: _endTime != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Shared toggle
              _SectionLabel(label: '공동 일정'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SwitchListTile(
                  value: _isShared,
                  onChanged: (val) => setState(() {
                    _isShared = val;
                    if (val) _eventColor = EventColor.shared;
                  }),
                  title: Text(
                    '파트너와 공동 일정',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '공동 일정은 보라색으로 표시됩니다.',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  activeColor: AppColors.shared,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Color picker (only if not shared)
              if (!_isShared) ...[
                _SectionLabel(label: '색상'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ColorOption(
                      color: AppColors.personalA,
                      label: '내 일정',
                      isSelected: _eventColor == EventColor.personalA,
                      onTap: () =>
                          setState(() => _eventColor = EventColor.personalA),
                    ),
                    const SizedBox(width: 12),
                    _ColorOption(
                      color: AppColors.personalB,
                      label: '파트너 일정',
                      isSelected: _eventColor == EventColor.personalB,
                      onTap: () =>
                          setState(() => _eventColor = EventColor.personalB),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isEditing ? '수정하기' : '일정 추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;

  const _PickerButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
