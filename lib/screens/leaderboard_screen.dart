import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Tournament> _tournaments = [];
  String? _selectedId;
  Map<String, dynamic>? _leaderboard;
  bool _loadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    widget.api
        .getTournaments()
        .then((items) {
          if (mounted) setState(() => _tournaments = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _tournaments = []);
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bảng xếp hạng',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTournamentList(),
          if (_selectedId != null) ...[
            const SizedBox(height: 24),
            _buildLeaderboardSection(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bảng xếp hạng', style: context.typography.h1),
        const SizedBox(height: 6),
        Text(
          'Thứ hạng và giải thưởng theo từng giải đấu.',
          style: context.typography.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildTournamentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn giải đấu', style: context.typography.h3),
        const SizedBox(height: 12),
        if (_tournaments.isEmpty)
          const LoadingShimmer(height: 60)
        else
          ..._tournaments.map(
            (t) => SelectableItemRow(
              title: t.name,
              subtitle: '${t.startDate} → ${t.endDate}',
              trailing: Icon(Icons.chevron_right,
                  size: 18, color: context.colors.muted),
              selected: _selectedId == t.id,
              onTap: () => _selectTournament(t.id),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    final entries = _leaderboard?['leaderboard'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Thứ hạng', style: context.typography.h3),
            if (_loadingLeaderboard) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(context.colors.primary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        if (_loadingLeaderboard || _leaderboard == null)
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LoadingShimmer(height: 70),
          ))
        else if (entries is! List || entries.isEmpty)
          const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Chưa có bảng xếp hạng',
            subtitle: 'Bảng xếp hạng sẽ hiển thị sau khi các trận đấu kết thúc.',
          )
        else
          ...entries.asMap().entries.map((entry) {
            final item = entry.value;
            if (item is! Map) return const SizedBox.shrink();
            return _LeaderboardRow(
              rank: entry.key + 1,
              horseName: item['horseName']?.toString() ?? '—',
              wins: item['wins']?.toString() ?? '0',
              prize: _formatPrize(item['totalPrize']),
            );
          }),
      ],
    );
  }

  void _selectTournament(String id) {
    setState(() {
      _selectedId = id;
      _leaderboard = null;
      _loadingLeaderboard = true;
    });
    widget.api
        .getTournamentLeaderboard(id)
        .then((data) {
          if (mounted && _selectedId == id) {
            setState(() {
              _leaderboard = data;
              _loadingLeaderboard = false;
            });
          }
        })
        .catchError((_) {
          if (mounted && _selectedId == id) {
            setState(() {
              _leaderboard = {'leaderboard': []};
              _loadingLeaderboard = false;
            });
          }
        });
  }

  String _formatPrize(Object? value) {
    if (value == null) return '—';
    final num = double.tryParse(value.toString());
    if (num == null) return value.toString();
    // Format with thousand separators
    final str = num.toStringAsFixed(0);
    final buf = StringBuffer();
    final chars = str.split('').reversed.toList();
    for (var i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) buf.write(',');
      buf.write(chars[i]);
    }
    return '\$${buf.toString().split('').reversed.join()}';
  }
}

// ── Leaderboard Row ───────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.horseName,
    required this.wins,
    required this.prize,
  });

  final int rank;
  final String horseName;
  final String wins;
  final String prize;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medal = switch (rank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', _ => null };
    final accentColor = switch (rank) {
      1 => context.colors.accent,
      2 => context.colors.muted,
      3 => context.colors.orange,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        accentColor: isTop3 ? accentColor : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: medal != null
                  ? Text(medal, style: const TextStyle(fontSize: 22))
                  : Text(
                      '#$rank',
                      style: context.typography.h3.copyWith(color: context.colors.muted),
                    ),
            ),
            const SizedBox(width: 12),
            // Horse name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    horseName,
                    style: context.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isTop3 ? context.colors.text : context.colors.text2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 12, color: context.colors.muted),
                      const SizedBox(width: 4),
                      Text('$wins trận thắng', style: context.typography.caption),
                    ],
                  ),
                ],
              ),
            ),
            // Prize
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.colors.accentLight,
                borderRadius: context.radii.sm,
                border: Border.all(color: context.colors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                prize,
                style: TextStyle(
                  fontFamily: context.typography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
