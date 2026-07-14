import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class AdminSchedulingScreen extends StatefulWidget {
  const AdminSchedulingScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<AdminSchedulingScreen> createState() => _AdminSchedulingScreenState();
}

class _AdminSchedulingScreenState extends State<AdminSchedulingScreen> {
  List<Race> _races = [];
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  Future<void> _fetchRaces() async {
    setState(() => _loading = true);
    try {
      final items = await widget.api.getRaces();
      if (mounted) setState(() => _races = items);
    } catch (_) {
      if (mounted) setState(() => _races = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý Cược & Lịch',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quản lý Dự đoán', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Đóng cổng cược hoặc Quyết toán kết quả các trận đấu.',
                  style: context.typography.bodyMuted,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: context.typography.body,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trận đấu...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchRaces,
              child: _buildRacesList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacesList() {
    if (_loading && _races.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: LoadingShimmer(height: 120),
        ),
      );
    }

    final filtered = _races.where((r) => r.name.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        title: 'Không có trận đấu',
        subtitle: 'Chưa có trận đấu nào trong hệ thống.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final race = filtered[index];
        return _buildRaceCard(race);
      },
    );
  }

  Widget _buildRaceCard(Race race) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    race.name,
                    style: context.typography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(label: race.status, variant: StatusBadge.fromStatus(race.status)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(race.id, 'close'),
                    icon: const Icon(Icons.lock_clock, size: 18),
                    label: const Text('Đóng cược'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.warning,
                      side: BorderSide(color: context.colors.warning.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(race.id, 'settle'),
                    icon: const Icon(Icons.monetization_on, size: 18),
                    label: const Text('Quyết toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String raceId, String action) async {
    final isClose = action == 'close';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(isClose ? 'Đóng cổng cược?' : 'Quyết toán cược?'),
        content: Text(isClose 
          ? 'Người chơi sẽ không thể tiếp tục đặt cược cho trận này.' 
          : 'Hệ thống sẽ tính điểm thưởng cho người chơi thắng cược.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isClose ? context.colors.warning : context.colors.success),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      if (isClose) {
        await widget.api.closePredictions(raceId);
      } else {
        await widget.api.settlePredictions(raceId);
      }
      if (!mounted) return;
      await showAppAlert(context, 'Thành công', 'Đã xử lý yêu cầu ${isClose ? 'Đóng cược' : 'Quyết toán'}.');
      _fetchRaces(); // Reload
    } catch (error) {
      if (!mounted) return;
      await showAppAlert(context, 'Thất bại', 'Đã xảy ra lỗi khi thực thi. Có thể trận này đã được xử lý hoặc chưa đủ điều kiện.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
