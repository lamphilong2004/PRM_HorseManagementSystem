import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<Tournament>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getTournaments()
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
      title: 'Giải đấu',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items == null) return _buildLoading();
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Không có giải đấu',
        subtitle: 'Hiện tại chưa có giải đấu nào.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _items!.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildSectionHeader();
        return _TournamentCard(tournament: _items![index - 1]);
      },
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tất cả giải đấu', style: context.typography.h1),
          const SizedBox(height: 6),
          Text(
            'Tìm thấy ${_items!.length} giải đấu',
            style: context.typography.bodyMuted,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: context.colors.border),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LoadingShimmer(height: 110),
      ),
    );
  }
}

// ── Tournament Card ───────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: context.typography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: context.colors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tournament.location,
                              style: context.typography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: tournament.startDate,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 12, color: context.colors.muted),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.event_outlined,
                  label: tournament.endDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surface2,
        borderRadius: context.radii.sm,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.muted),
          const SizedBox(width: 5),
          Text(label, style: context.typography.caption),
        ],
      ),
    );
  }
}
