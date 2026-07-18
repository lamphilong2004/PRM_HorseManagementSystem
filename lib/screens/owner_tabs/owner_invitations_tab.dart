import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class OwnerInvitationsTab extends StatefulWidget {
  const OwnerInvitationsTab({super.key, required this.api});
  final ApiService api;

  @override
  State<OwnerInvitationsTab> createState() => _OwnerInvitationsTabState();
}

class _OwnerInvitationsTabState extends State<OwnerInvitationsTab> {
  List<Invite>? _items;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final items = await widget.api.getInvites();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleAccept(String inviteId) async {
    try {
      await widget.api.acceptInvitation(inviteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chấp nhận lời mời.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _handleReject(String inviteId) async {
    try {
      await widget.api.rejectInvitation(inviteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingShimmer(height: 160),
        ),
      );
    }
    if (_items != null && _items!.isEmpty) {
      return const EmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'Không có lời mời',
        subtitle: 'Bạn hiện không có lời mời nào.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: (_items?.length ?? 0) + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lời mời của tôi', style: context.typography.h1),
                  const SizedBox(height: 6),
                  Text('Quản lý lời mời liên quan đến ngựa của bạn', style: context.typography.bodyMuted),
                  const SizedBox(height: 16),
                  Container(height: 1, color: context.colors.border),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }
          final invite = _items![index - 1];
          final isPending = invite.status.toLowerCase() == 'pending';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invite.raceName ?? 'Giải đấu',
                        style: context.typography.h3,
                      ),
                      StatusBadge(
                        label: invite.status.toUpperCase(),
                        variant: StatusBadge.fromStatus(invite.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('🐎', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(invite.horseName, style: context.typography.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (invite.message != null && invite.message!.isNotEmpty)
                    Text('"${invite.message}"', style: context.typography.caption.copyWith(fontStyle: FontStyle.italic)),
                  
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAccept(invite.id),
                            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
                            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleReject(invite.id),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            child: const Text('Từ chối'),
                          ),
                        ),
                      ],
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
}
