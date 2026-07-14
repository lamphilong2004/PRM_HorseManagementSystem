import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class JockeyScheduleScreen extends StatefulWidget {
  const JockeyScheduleScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<JockeyScheduleScreen> createState() => _JockeyScheduleScreenState();
}

class _JockeyScheduleScreenState extends State<JockeyScheduleScreen> {
  List<Race>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getJockeyRaces()
        .then((items) {
          if (mounted) setState(() => _items = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _items = []);
        });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Race Schedule', style: context.typography.h2.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Manage your race entries and timings.', style: context.typography.bodyMuted),
            ],
          ),
        ),
        
        // Horizontal Date Picker
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildDateCard(context, 'MON', '12', isPast: true),
              _buildDateCard(context, 'TUE', '13', isPast: true),
              _buildDateCard(context, 'WED', '14', isActive: true),
              _buildDateCard(context, 'THU', '15'),
              _buildDateCard(context, 'FRI', '16'),
              _buildDateCard(context, 'SAT', '17'),
              _buildDateCard(context, 'SUN', '18'),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Race ListView
        Expanded(
          child: _items!.isEmpty 
            ? const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Lịch trình trống',
                subtitle: 'Bạn chưa có lịch thi đấu nào sắp tới.',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _items!.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items!.length) {
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
                          Text('End of scheduled races', style: context.typography.label.copyWith(color: context.colors.muted)),
                        ],
                      ),
                    );
                  }
                  final race = _items![index];
                  // Determine color theme based on index for the badge
                  final Color themeColor = index % 3 == 0 ? context.colors.accent
                                        : index % 3 == 1 ? context.colors.primary 
                                        : const Color(0xFFFFB695); // Warm accent color
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        showAppBottomSheet(
                          context,
                          title: race.name,
                          subtitle: _formatDate(race.scheduledAt),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Trạng thái:', style: context.typography.bodyMuted),
                                  StatusBadge(label: _translateStatus(race.status), variant: StatusBadge.fromStatus(race.status)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                label: 'Xem kết quả',
                                icon: Icons.emoji_events_outlined,
                                onPressed: () {
                                  Navigator.pop(context);
                                  showRaceResultsModal(
                                    context,
                                    raceName: race.name,
                                    onFetchResults: () => widget.api.getRaceResults(race.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Badge/Name and Time
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
                            // Middle: Location
                            Row(
                              children: [
                                Icon(Icons.stadium_outlined, size: 18, color: context.colors.muted),
                                const SizedBox(width: 8),
                                Text(
                                  'ERMS Main Stadium', // Dummy location matching HTML
                                  style: context.typography.bodyMuted.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Divider
                            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                            const SizedBox(height: 16),
                            // Bottom Row: Horse & Arrow
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.pets, size: 18, color: context.colors.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'My Assigned Horse', // Dummy horse name
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

  Widget _buildDateCard(BuildContext context, String day, String date, {bool isActive = false, bool isPast = false}) {
    return Container(
      width: 64,
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
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isActive ? Colors.white : context.colors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : context.colors.text,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ]
        ],
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
