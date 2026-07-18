import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  List<Prediction>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getPredictions()
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
      title: 'Dự đoán',
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
          child: LoadingShimmer(height: 90),
        ),
      );
    }
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'Không có dự đoán',
        subtitle: 'Bạn chưa thực hiện lượt dự đoán nào.',
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
                Text('Dự đoán của tôi', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Có ${_items!.length} lượt dự đoán',
                  style: context.typography.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: 4),
              ],
            ),
          );
        }
        return _PredictionCard(prediction: _items![index - 1]);
      },
    );
  }
}

// ── Prediction Card ───────────────────────────────────────────

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.prediction});

  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final statusVariant = StatusBadge.fromStatus(prediction.status);

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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.colors.infoLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.analytics_outlined,
                      size: 19, color: context.colors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                         prediction.raceName?.isNotEmpty == true
                            ? prediction.raceName!
                            : 'Trận đấu ${prediction.raceId.substring(0, 8)}…',
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                          label: prediction.status, variant: statusVariant),
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
                // Horse picked
                Expanded(
                  child: _Detail(
                    icon: Icons.pets_outlined,
                    label: 'Ngựa đua',
                    value: prediction.pickedHorseName.isNotEmpty
                        ? prediction.pickedHorseName
                        : '—',
                  ),
                ),
                // Bet amount
                if (prediction.betAmount != null) ...[
                  const SizedBox(width: 12),
                  _Detail(
                    icon: Icons.attach_money_rounded,
                    label: 'Đặt cược',
                    value: _formatAmount(prediction.betAmount),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(num? amount) {
    if (amount == null) return '—';
    final str = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    final chars = str.split('').reversed.toList();
    for (var i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) buf.write(',');
      buf.write(chars[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: context.colors.muted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: context.typography.captionUpper),
            const SizedBox(height: 2),
            Text(value, style: context.typography.body.copyWith(color: context.colors.text)),
          ],
        ),
      ],
    );
  }
}
