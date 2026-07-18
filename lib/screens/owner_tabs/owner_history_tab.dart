import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class OwnerHistoryTab extends StatefulWidget {
  const OwnerHistoryTab({super.key, required this.api});
  final ApiService api;

  @override
  State<OwnerHistoryTab> createState() => _OwnerHistoryTabState();
}

class _OwnerHistoryTabState extends State<OwnerHistoryTab> {
  List<Registration>? _registrations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _registrations = null);
    widget.api.getOwnerRegistrations().then((items) {
      if (mounted) setState(() => _registrations = items);
    }).catchError((e) {
      if (mounted) {
        setState(() => _registrations = []);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_registrations == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer(height: 100),
        ),
      );
    }
    if (_registrations!.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Chưa có lịch sử',
        subtitle: 'Bạn chưa có đơn đăng ký giải đấu nào.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _registrations!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lịch sử đăng ký', style: context.typography.h1),
                  const SizedBox(height: 6),
                  Text('Theo dõi trạng thái duyệt đơn đăng ký của bạn', style: context.typography.bodyMuted),
                  const SizedBox(height: 16),
                  Container(height: 1, color: context.colors.border),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }
          final reg = _registrations![index - 1];
          final isRejected = reg.status.toUpperCase() == 'REJECTED';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
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
                        child: const Center(child: Text('🐎', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reg.horseName ?? 'Ngựa vô danh', style: context.typography.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('Giải đấu: ${reg.raceName ?? 'Không rõ'}', style: context.typography.caption),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: _translateStatus(reg.confirmedByOwner ? 'confirmed' : reg.status),
                        variant: StatusBadge.fromStatus(reg.confirmedByOwner ? 'confirmed' : reg.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: context.colors.primary),
                      const SizedBox(width: 6),
                      Text('Nài ngựa: ${reg.jockeyName ?? 'Chưa thuê'}', style: context.typography.body.copyWith(fontSize: 13)),
                    ],
                  ),
                  if (isRejected && reg.rejectionReason != null && reg.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Lý do từ chối: ${reg.rejectionReason}', style: context.typography.caption.copyWith(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _translateStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending'   => 'Đang chờ',
      'approved'  => 'Đã duyệt',
      'rejected'  => 'Bị từ chối',
      'confirmed' => 'Đã chốt',
      _           => status,
    };
  }
}
