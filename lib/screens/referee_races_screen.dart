import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
import 'referee_report_screen.dart';

class RefereeRacesScreen extends StatefulWidget {
  const RefereeRacesScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<RefereeRacesScreen> createState() => _RefereeRacesScreenState();
}

class _RefereeRacesScreenState extends State<RefereeRacesScreen> {
  List<Race>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getRefereeRaces()
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
      title: 'Trận đấu của tôi',
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
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.gavel_outlined,
        title: 'Không có trận đấu được phân công',
        subtitle: 'Bạn không có trận đấu nào được phân công giám sát.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _items!.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trận đấu phân công', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Bạn đang giám sát ${_items!.length} trận đấu.',
                  style: context.typography.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: 4),
              ],
            ),
          );
        }
        final race = _items![index - 1];
        final variant = StatusBadge.fromStatus(race.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RefereeReportScreen(api: widget.api, race: race),
                ),
              );
            },
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
                          color: context.colors.infoLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.gavel,
                            size: 20, color: context.colors.info),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(race.name, style: context.typography.h3),
                            const SizedBox(height: 5),
                            StatusBadge(label: _translateStatus(race.status), variant: variant),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: context.colors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 13, color: context.colors.muted),
                      const SizedBox(width: 6),
                      Text(_formatDate(race.scheduledAt), style: context.typography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      'scheduled' => 'Lên lịch',
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
