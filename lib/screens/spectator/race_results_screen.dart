import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class RaceResultsScreen extends StatefulWidget {
  const RaceResultsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<RaceResultsScreen> createState() => _RaceResultsScreenState();
}

class _RaceResultsScreenState extends State<RaceResultsScreen> {
  List<Race> _races = [];

  @override
  void initState() {
    super.initState();
    widget.api
        .getRaces()
        .then((items) {
          if (mounted) setState(() => _races = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _races = []);
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kết quả vòng đua',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildRaceSelector(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kết quả vòng đua', style: context.typography.h1),
        const SizedBox(height: 6),
        Text(
          'Chọn một vòng đua để xem thứ tự về đích.',
          style: context.typography.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildRaceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn vòng đua', style: context.typography.h3),
        const SizedBox(height: 12),
        if (_races.isEmpty)
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LoadingShimmer(height: 60),
          ))
        else
          ..._races.map((race) {
            final variant = StatusBadge.fromStatus(race.status);
            final statusStr = _translateStatus(race.status);
            return SelectableItemRow(
              title: race.name,
              subtitle: statusStr,
              trailing: StatusBadge(label: statusStr, variant: variant),
              selected: false,
              onTap: () {
                showRaceResultsModal(
                  context,
                  raceName: race.name,
                  onFetchResults: () => widget.api.getRaceResults(race.id),
                );
              },
            );
          }),
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
      'scheduled' => 'Lên lịch',
      'ongoing'   => 'Đang diễn ra',
      'won'       => 'Thắng',
      'lost'      => 'Thua',
      _           => status,
    };
  }
}
