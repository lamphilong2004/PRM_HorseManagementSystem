import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen({
    super.key,
    required this.api,
    required this.tournamentId,
  });

  final ApiService api;
  final String tournamentId;

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  Tournament? _tournament;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() {
    setState(() {
      _loading = true;
      _error = null;
    });
    widget.api.getTournamentById(widget.tournamentId).then((tournament) {
      if (mounted) {
        setState(() {
          _tournament = tournament;
          _loading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _error = err?.toString() ?? 'Không thể tải chi tiết giải đấu';
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chi tiết giải đấu',
      body: RefreshIndicator(
        onRefresh: () async => _fetchDetails(),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(height: 120),
            const SizedBox(height: 20),
            LoadingShimmer(height: 160),
            const SizedBox(height: 20),
            LoadingShimmer(height: 100),
          ],
        ),
      );
    }

    if (_error != null || _tournament == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Lỗi tải dữ liệu',
            subtitle: _error ?? 'Không tìm thấy giải đấu',
          ),
        ),
      );
    }

    final t = _tournament!;
    final prizePoolFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: t.currency ?? 'VND',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            accentColor: context.colors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🏆 GIẢI ĐẤU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (t.status != null)
                      StatusBadge(
                        label: _translateStatus(t.status!),
                        variant: StatusBadge.fromStatus(t.status!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t.name,
                  style: context.typography.h1.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: context.colors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.location,
                        style: context.typography.body.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatDetail(
                  context,
                  title: 'Giải thưởng',
                  value: t.prizePool != null ? prizePoolFormatter.format(t.prizePool) : 'Chưa rõ',
                  icon: Icons.monetization_on_outlined,
                  color: context.colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatDetail(
                  context,
                  title: 'Thời gian bắt đầu',
                  value: _formatDate(t.startDate),
                  icon: Icons.calendar_today_outlined,
                  color: context.colors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatDetail(
                  context,
                  title: 'Thời gian kết thúc',
                  value: _formatDate(t.endDate),
                  icon: Icons.event_outlined,
                  color: context.colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatDetail(
                  context,
                  title: 'Ngựa đã đăng ký',
                  value: '${t.registeredCount ?? 0} / ${t.maxHorses ?? 0}',
                  icon: Icons.pets_outlined,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatDetail(
                  context,
                  title: 'Vòng đấu hiện tại',
                  value: 'Vòng ${t.currentRound ?? 1} / ${t.totalRounds ?? 0}',
                  icon: Icons.emoji_events_outlined,
                  color: context.colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description Section
          if (t.description != null && t.description!.isNotEmpty) ...[
            Text(
              'Mô tả giải đấu',
              style: context.typography.h2,
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.description!,
                style: context.typography.body.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildStatDetail(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: context.typography.captionUpper.copyWith(fontSize: 10, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.typography.h3.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    return switch (status.toLowerCase()) {
      'draft'               => 'Bản nháp',
      'published'           => 'Đang mở đăng ký',
      'registration_closed' => 'Đóng đăng ký',
      'bracket_generated'   => 'Đã tạo sơ đồ',
      'ongoing'             => 'Đang diễn ra',
      'completed'           => 'Hoàn thành',
      'cancelled'           => 'Đã hủy',
      _                     => status,
    };
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
