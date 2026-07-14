import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getNotifications()
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
      title: 'Thông báo',
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
          child: LoadingShimmer(height: 80),
        ),
      );
    }
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Không có thông báo',
        subtitle: 'Bạn không có thông báo nào mới.',
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
                Text('Thông báo', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Có ${_items!.length} thông báo',
                  style: context.typography.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: 4),
              ],
            ),
          );
        }
        return _NotificationCard(
          item: _items![index - 1],
          api: widget.api,
        );
      },
    );
  }
}

// ── Notification Card ─────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.api});

  final Map<String, dynamic> item;
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    final title   = item['title']?.toString() ?? item['type']?.toString() ?? 'Thông báo';
    final message = item['message']?.toString() ?? '';
    final type    = item['type']?.toString() ?? '';
    final (icon, iconBg, iconColor) = _iconConfig(context, type);

    final rawRaceId = item['raceId'] ?? item['race']?['id'] ?? item['data']?['raceId'] ?? item['prediction']?['raceId'];
    final raceId = rawRaceId?.toString();
    final hasRaceId = raceId != null && raceId.isNotEmpty;

    Widget card = GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message, style: context.typography.bodyMuted, maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (hasRaceId) {
      card = GestureDetector(
        onTap: () {
          showRaceResultsModal(
            context,
            raceName: title,
            onFetchResults: () => api.getRaceResults(raceId),
          );
        },
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: card,
    );
  }

  (IconData, Color, Color) _iconConfig(BuildContext context, String type) {
    return switch (type.toLowerCase()) {
      'prediction_won' || 'won'  => (Icons.emoji_events, context.colors.accentLight,  context.colors.accent),
      'prediction_lost' || 'lost'=> (Icons.close_rounded,context.colors.dangerLight,  context.colors.danger),
      'race_started'             => (Icons.flag,          context.colors.infoLight,    context.colors.info),
      'race_completed'           => (Icons.check_circle,  context.colors.successLight, context.colors.success),
      'system'                   => (Icons.info_outline,  context.colors.surface2,     context.colors.muted),
      _                          => (Icons.notifications_outlined, context.colors.surface2, context.colors.muted),
    };
  }
}
