import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class JockeyScheduleScreen extends StatefulWidget {
  const JockeyScheduleScreen({super.key, required this.api, this.initialDateStr});

  final ApiService api;
  final String? initialDateStr;

  @override
  State<JockeyScheduleScreen> createState() => _JockeyScheduleScreenState();
}

class _JockeyScheduleScreenState extends State<JockeyScheduleScreen> {
  List<Race>? _items;
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  bool _isMonthView = false;
  bool _showAllInPeriod = false;

  @override
  void initState() {
    super.initState();
    
    print("DEBUG jockey_schedule_screen: initialDateStr = ${widget.initialDateStr}");
    DateTime start = DateTime.now();
    if (widget.initialDateStr != null && widget.initialDateStr!.isNotEmpty) {
      try {
        start = DateTime.parse(widget.initialDateStr!).toLocal();
        print("DEBUG jockey_schedule_screen: parsed start date = $start");
      } catch (e) {
        print("DEBUG jockey_schedule_screen: parse error = $e");
      }
    }
    _selectedDate = start;
    _focusedDate = start;

    widget.api
        .getJockeyRaces()
        .then((items) {
          print("DEBUG jockey_schedule_screen: getJockeyRaces returned ${items.length} items: $items");
          for (var item in items) {
            print("DEBUG jockey_schedule_screen: item: name=${item.name}, scheduledAt=${item.scheduledAt}, location=${item.location}");
          }
          if (mounted) setState(() => _items = items);
        })
        .catchError((err) {
          print("DEBUG jockey_schedule_screen: getJockeyRaces error = $err");
          if (mounted) setState(() => _items = []);
        });
  }

  List<DateTime> _getDaysInWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final prevMonthPadding = firstDayOfMonth.weekday - 1;
    final startCalendarDate = firstDayOfMonth.subtract(Duration(days: prevMonthPadding));
    return List.generate(42, (i) => startCalendarDate.add(Duration(days: i)));
  }

  bool _hasRaceOnDay(DateTime date) {
    if (_items == null) return false;
    return _items!.any((race) {
      try {
        final raceDate = DateTime.parse(race.scheduledAt).toLocal();
        return raceDate.year == date.year &&
               raceDate.month == date.month &&
               raceDate.day == date.day;
      } catch (_) {
        return false;
      }
    });
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear + daysOffset - 1) / 7).floor() + 1;
  }

  String _getMonthYearLabel(DateTime date) {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return '${months[date.month - 1]}, ${date.year}';
  }

  String _getWeekdayLabel(int weekday) {
    return switch (weekday) {
      1 => 'MON',
      2 => 'TUE',
      3 => 'WED',
      4 => 'THU',
      5 => 'FRI',
      6 => 'SAT',
      7 => 'SUN',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lịch trình thi đấu',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer(height: 100),
        ),
      );
    }

    final weekDays = _getDaysInWeek(_focusedDate);
    final filteredRaces = _items!.where((race) {
      try {
        final raceDate = DateTime.parse(race.scheduledAt).toLocal();
        if (_showAllInPeriod) {
          if (_isMonthView) {
            return raceDate.year == _focusedDate.year && raceDate.month == _focusedDate.month;
          } else {
            final startOfWeek = DateTime(weekDays.first.year, weekDays.first.month, weekDays.first.day);
            final endOfWeek = DateTime(weekDays.last.year, weekDays.last.month, weekDays.last.day, 23, 59, 59);
            return raceDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
                   raceDate.isBefore(endOfWeek.add(const Duration(seconds: 1)));
          }
        }
        return raceDate.year == _selectedDate.year &&
               raceDate.month == _selectedDate.month &&
               raceDate.day == _selectedDate.day;
      } catch (_) {
        return false;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title with Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lịch thi đấu', style: context.typography.h2.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Quản lý lịch trình và thời gian thi đấu.', style: context.typography.bodyMuted),
                  ],
                ),
              ),
              _buildViewToggle(),
            ],
          ),
        ),

        // Navigation controls for Month/Week
        _buildCalendarHeader(),

        // Dynamic week or month view
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isMonthView ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.none,
            child: Row(
              children: weekDays.map((day) {
                final isSelected = day.year == _selectedDate.year &&
                                   day.month == _selectedDate.month &&
                                   day.day == _selectedDate.day;
                final hasRace = _hasRaceOnDay(day);
                return _buildDateCard(context, day, isActive: isSelected, hasRace: hasRace);
              }).toList(),
            ),
          ),
          secondChild: _buildMonthCalendar(context),
        ),

        // Sub-header for filtered list
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAllInPeriod
                    ? (_isMonthView ? 'Tất cả trận đấu trong tháng' : 'Tất cả trận đấu trong tuần')
                    : 'Trận đấu ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: context.typography.label.copyWith(color: context.colors.text),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllInPeriod = !_showAllInPeriod;
                  });
                },
                child: Text(
                  _showAllInPeriod ? 'Lọc theo ngày' : 'Xem tất cả',
                  style: TextStyle(color: context.colors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Race ListView
        Expanded(
          child: filteredRaces.isEmpty 
            ? const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Lịch trình trống',
                subtitle: 'Không có lịch thi đấu nào.',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filteredRaces.length + 1,
                itemBuilder: (context, index) {
                  if (index == filteredRaces.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: 0.3,
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Icon(Icons.event_note, size: 48, color: context.colors.text),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Hết lịch trình hiển thị', style: context.typography.label.copyWith(color: context.colors.muted)),
                        ],
                      ),
                    );
                  }
                  final race = filteredRaces[index];
                  final Color themeColor = index % 3 == 0 ? context.colors.accent
                                        : index % 3 == 1 ? context.colors.primary 
                                        : const Color(0xFFFFB695);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        showAppBottomSheet(
                          context,
                          title: race.name,
                          subtitle: _formatDate(race.scheduledAt),
                          child: _JockeyRaceDetailSheet(
                            raceId: race.id,
                            api: widget.api,
                            raceName: race.name,
                            formattedDate: _formatDate(race.scheduledAt),
                            status: race.status,
                          ),
                        );
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          'RACE 0${index + 1}',
                                          style: context.typography.caption.copyWith(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        race.name,
                                        style: context.typography.h3.copyWith(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _extractTime(race.scheduledAt),
                                      style: context.typography.h3.copyWith(color: context.colors.primary, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Post Time',
                                      style: context.typography.caption.copyWith(color: context.colors.muted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.stadium_outlined, size: 18, color: context.colors.muted),
                                const SizedBox(width: 8),
                                Text(
                                  race.location != null && race.location!.isNotEmpty
                                      ? race.location!
                                      : 'ERMS Main Stadium',
                                  style: context.typography.bodyMuted.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.pets, size: 18, color: context.colors.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'My Assigned Horse',
                                      style: context.typography.body.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Icon(Icons.chevron_right, color: context.colors.muted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Tuần', !_isMonthView),
          _buildToggleOption('Tháng', _isMonthView),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMonthView = label == 'Tháng';
          _showAllInPeriod = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? LinearGradient(
                  colors: [context.colors.primary, context.colors.accent],
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : context.colors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_isMonthView) {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
                } else {
                  _focusedDate = _focusedDate.subtract(const Duration(days: 7));
                }
              });
            },
          ),
          Text(
            _isMonthView 
                ? _getMonthYearLabel(_focusedDate)
                : 'Tuần ${_getWeekNumber(_focusedDate)} - ${_getMonthYearLabel(_focusedDate)}',
            style: context.typography.h3.copyWith(fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_isMonthView) {
                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
                } else {
                  _focusedDate = _focusedDate.add(const Duration(days: 7));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(BuildContext context) {
    final days = _getDaysInMonth(_focusedDate);
    final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels.map((label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: context.typography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.muted,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isCurrentMonth = day.month == _focusedDate.month;
              final isSelected = day.year == _selectedDate.year &&
                                 day.month == _selectedDate.month &&
                                 day.day == _selectedDate.day;
              final hasRace = _hasRaceOnDay(day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    _focusedDate = day;
                    _showAllInPeriod = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [context.colors.primary, context.colors.accent],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? context.colors.text
                                  : context.colors.muted.withValues(alpha: 0.3),
                        ),
                      ),
                      if (hasRace)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, DateTime date, {required bool isActive, required bool hasRace}) {
    final dayLabel = _getWeekdayLabel(date.weekday);
    final dateLabel = date.day.toString();
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _showAllInPeriod = false;
        });
      },
      child: Container(
        width: 60,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? null : context.colors.surface2.withValues(alpha: isPast ? 0.4 : 1.0),
          gradient: isActive 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [context.colors.primary, context.colors.accent],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? null : Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: isActive 
              ? [BoxShadow(color: context.colors.primary.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isActive ? Colors.white : context.colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : context.colors.text,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
            else if (hasRace)
              Container(width: 4, height: 4, decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle))
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _extractTime(String iso) {
    if (iso.isEmpty) return 'TBA';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return 'TBA';
    }
  }


  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
             '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _JockeyRaceDetailSheet extends StatefulWidget {
  const _JockeyRaceDetailSheet({
    required this.raceId,
    required this.api,
    required this.raceName,
    required this.formattedDate,
    required this.status,
  });

  final String raceId;
  final ApiService api;
  final String raceName;
  final String formattedDate;
  final String status;

  @override
  State<_JockeyRaceDetailSheet> createState() => _JockeyRaceDetailSheetState();
}

class _JockeyRaceDetailSheetState extends State<_JockeyRaceDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _loading = true;
      _error = null;
    });
    widget.api.getJockeyRaceDetail(widget.raceId).then((data) {
      if (mounted) {
        setState(() {
          _detail = data;
          _loading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _error = err?.toString() ?? 'Không thể tải chi tiết cuộc đua';
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Đang tải thông tin chi tiết...', style: context.typography.bodyMuted),
          ],
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: context.colors.danger, size: 48),
            const SizedBox(height: 16),
            Text(_error ?? 'Lỗi tải dữ liệu', style: context.typography.body),
            const SizedBox(height: 16),
            AppButton(
              label: 'Thử lại',
              onPressed: _loadDetail,
              fullWidth: false,
            ),
          ],
        ),
      );
    }

    final data = _detail!;
    final horse = data['horse'] as Map?;
    final owner = data['owner'] as Map?;
    final registrationStatus = data['registrationStatus']?.toString() ?? widget.status;
    
    // Tình trạng / Loại đua
    final distance = data['distance']?.toString() ?? '—';
    final location = data['location']?.toString() ?? '—';
    final raceType = data['raceType']?.toString() ?? '—';
    final trackCondition = data['trackCondition']?.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trạng thái cuộc đua
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Trạng thái:', style: context.typography.bodyMuted),
            StatusBadge(
              label: _translateStatus(widget.status),
              variant: StatusBadge.fromStatus(widget.status),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Trạng thái đăng ký của Jockey/Ngựa trong cuộc đua
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trạng thái phân công:', style: context.typography.bodyMuted.copyWith(fontSize: 13)),
              Text(
                _translateStatus(registrationStatus),
                style: TextStyle(
                  color: registrationStatus.toLowerCase() == 'confirmed' || registrationStatus.toLowerCase() == 'accepted'
                      ? const Color(0xFF10B981)
                      : context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 🐎 THÔNG TIN NGỰA ĐUA
        Text(
          '🐎 THÔNG TIN NGỰA ĐUA',
          style: context.typography.captionUpper.copyWith(
            fontSize: 11,
            color: context.colors.muted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        if (horse != null) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horse['name']?.toString() ?? 'Chưa rõ',
                  style: context.typography.h3.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubDetailItem('Giống', horse['breed']?.toString() ?? '—'),
                    _buildSubDetailItem('Giới tính', _translateGender(horse['gender']?.toString())),
                    _buildSubDetailItem('Cân nặng', horse['weight'] != null ? '${horse['weight']} kg' : '—'),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Text('Chưa phân công ngựa', style: context.typography.body),
        ],
        const SizedBox(height: 24),

        // 👤 THÔNG TIN CHỦ NGỰA
        Text(
          '👤 THÔNG TIN CHỦ NGỰA',
          style: context.typography.captionUpper.copyWith(
            fontSize: 11,
            color: context.colors.muted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        if (owner != null) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner['fullName']?.toString() ?? 'Chưa rõ',
                  style: context.typography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: context.colors.muted),
                    const SizedBox(width: 8),
                    Text(owner['phone']?.toString() ?? '—', style: context.typography.bodyMuted),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.mail_outline, size: 14, color: context.colors.muted),
                    const SizedBox(width: 8),
                    Text(owner['email']?.toString() ?? '—', style: context.typography.bodyMuted),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Text('Chưa cập nhật thông tin chủ ngựa', style: context.typography.body),
        ],
        const SizedBox(height: 24),

        // 🏁 CHI TIẾT CUỘC ĐUA
        Text(
          '🏁 CHI TIẾT CUỘC ĐUA',
          style: context.typography.captionUpper.copyWith(
            fontSize: 11,
            color: context.colors.muted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRowInfo('Cự ly', '$distance m'),
              const Divider(height: 16),
              _buildRowInfo('Địa điểm', location),
              const Divider(height: 16),
              _buildRowInfo('Loại hình', _translateRaceType(raceType)),
              const Divider(height: 16),
              _buildRowInfo('Mặt sân', _translateTrackCondition(trackCondition)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Xem kết quả Button if completed
        if (widget.status.toLowerCase() == 'completed') ...[
          AppButton(
            label: 'Xem kết quả cuộc đua',
            icon: Icons.emoji_events_outlined,
            onPressed: () {
              Navigator.pop(context);
              showRaceResultsModal(
                context,
                raceName: widget.raceName,
                onFetchResults: () => widget.api.getRaceResults(widget.raceId),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSubDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.typography.caption.copyWith(color: context.colors.muted)),
        const SizedBox(height: 2),
        Text(value, style: context.typography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.typography.bodyMuted),
        Text(value, style: context.typography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _translateStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending'   => 'Đang chờ',
      'open'      => 'Đang mở',
      'active'    => 'Hoạt động',
      'completed' => 'Hoàn thành',
      'approved'  => 'Đã duyệt',
      'confirmed' => 'Xác nhận',
      'rejected'  => 'Bị từ chối',
      'inactive'  => 'Không hoạt động',
      'cancelled' => 'Đã hủy',
      'scheduled' => 'Sắp tới',
      'ongoing'   => 'Đang diễn ra',
      'won'       => 'Thắng',
      'lost'      => 'Thua',
      _           => status,
    };
  }

  String _translateGender(String? gender) {
    if (gender == null) return '—';
    return switch (gender.toUpperCase()) {
      'MALE' => 'Đực',
      'FEMALE' => 'Cái',
      'GELDING' => 'Thiến',
      _ => gender,
    };
  }

  String _translateRaceType(String type) {
    return switch (type.toUpperCase()) {
      'FLAT' => 'Đua phẳng (Flat)',
      'HURDLE' => 'Đua vượt rào (Hurdle)',
      'STEEPLECHASE' => 'Đua chướng ngại vật (Steeplechase)',
      _ => type,
    };
  }

  String _translateTrackCondition(String condition) {
    return switch (condition.toUpperCase()) {
      'GOOD' => 'Tốt',
      'FIRM' => 'Cứng',
      'MUDDY' => 'Bùn lầy',
      'YIELDING' => 'Mềm',
      'HEAVY' => 'Nặng',
      _ => condition,
    };
  }
}
