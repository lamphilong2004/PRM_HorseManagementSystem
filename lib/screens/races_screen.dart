import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class RacesScreen extends StatefulWidget {
  const RacesScreen({super.key, required this.api, this.role});

  final ApiService api;
  final Role? role;

  @override
  State<RacesScreen> createState() => _RacesScreenState();
}

class _RacesScreenState extends State<RacesScreen> {
  List<Race>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getRaces()
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
      title: 'Vòng đua',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer(height: 100),
        ),
      );
    }
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        title: 'Không có vòng đua',
        subtitle: 'Hiện chưa có vòng đua nào được lên lịch.',
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
                Text('Tất cả vòng đua', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Tìm thấy ${_items!.length} vòng đua',
                  style: context.typography.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: 4),
              ],
            ),
          );
        }
        return _RaceCard(
          race: _items![index - 1],
          api: widget.api,
          role: widget.role,
        );
      },
    );
  }
}

class _RaceCard extends StatelessWidget {
  const _RaceCard({required this.race, required this.api, this.role});

  final Race race;
  final ApiService api;
  final Role? role;

  @override
  Widget build(BuildContext context) {
    final statusVariant = StatusBadge.fromStatus(race.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🏇', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        race.name,
                        style: context.typography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(label: _translateStatus(race.status), variant: statusVariant),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: context.colors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 13, color: context.colors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(race.scheduledAt),
                    style: context.typography.caption,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
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
