import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class HorsesScreen extends StatefulWidget {
  const HorsesScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<HorsesScreen> createState() => _HorsesScreenState();
}

class _HorsesScreenState extends State<HorsesScreen> {
  List<Horse>? _items;

  @override
  void initState() {
    super.initState();
    widget.api
        .getHorses()
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
      title: 'Ngựa của tôi',
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
        icon: Icons.pets_outlined,
        title: 'Không có ngựa đua',
        subtitle: 'Bạn chưa đăng ký chiến mã nào.',
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
                Text('Ngựa của tôi', style: context.typography.h1),
                const SizedBox(height: 6),
                Text(
                  'Có ${_items!.length} chiến mã',
                  style: context.typography.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: 4),
              ],
            ),
          );
        }
        final horse = _items![index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🐎', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horse.name,
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12, color: context.colors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Mã chủ sở hữu: ${horse.ownerId.substring(0, 8)}…',
                              style: context.typography.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: context.colors.muted),
              ],
            ),
          ),
        );
      },
    );
  }
}
