import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';
import '../owner_race_registration_sheet.dart';

class OwnerRegistrationTab extends StatefulWidget {
  const OwnerRegistrationTab({super.key, required this.api});
  final ApiService api;

  @override
  State<OwnerRegistrationTab> createState() => _OwnerRegistrationTabState();
}

class _OwnerRegistrationTabState extends State<OwnerRegistrationTab> {
  List<Race>? _races;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _races = null);
    widget.api.getRaces().then((items) {
      // Filter races to only show upcoming/open ones for registration (e.g. status != COMPLETED)
      final available = items.where((r) => r.status.toUpperCase() != 'COMPLETED' && r.status.toUpperCase() != 'CANCELLED').toList();
      if (mounted) setState(() => _races = available);
    }).catchError((_) {
      if (mounted) setState(() => _races = []);
    });
  }

  void _registerForRace(Race race) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OwnerRaceRegistrationSheet(api: widget.api, race: race),
    );
    if (result == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_races == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer(height: 100),
        ),
      );
    }
    if (_races!.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'Không có vòng đua',
        subtitle: 'Hiện không có vòng đua nào đang mở đăng ký.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _races!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đăng ký giải đấu', style: context.typography.h1),
                  const SizedBox(height: 6),
                  Text('Các vòng đua đang mở', style: context.typography.bodyMuted),
                  const SizedBox(height: 16),
                  Container(height: 1, color: context.colors.border),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }
          final race = _races![index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: Text('🏇', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(race.name, style: context.typography.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            StatusBadge(label: _translateStatus(race.status), variant: StatusBadge.fromStatus(race.status)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 13, color: context.colors.muted),
                      const SizedBox(width: 6),
                      Text(_formatDate(race.scheduledAt), style: context.typography.caption),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _registerForRace(race),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Đăng ký', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _translateStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending'   => 'Đang chờ',
      'open'      => 'Đang mở',
      'active'    => 'Hoạt động',
      'completed' => 'Hoàn thành',
      'scheduled' => 'Lên lịch',
      _           => status,
    };
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
