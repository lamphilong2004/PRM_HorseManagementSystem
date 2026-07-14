import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  List<Invite>? _items;

  Future<void> _load() async {
    try {
      final items = await widget.api.getInvites();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _items = []);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _handleAccept(String inviteId) async {
    try {
      await widget.api.acceptInvitation(inviteId);
      if (!mounted) return;
      await showAppAlert(context, 'Thành công', 'Đã chấp nhận lời mời đua.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showAppAlert(context, 'Lỗi', 'Không thể chấp nhận lời mời.', isError: true);
    }
  }

  Future<void> _handleReject(String inviteId) async {
    try {
      await widget.api.rejectInvitation(inviteId);
      if (!mounted) return;
      await showAppAlert(context, 'Thành công', 'Đã từ chối lời mời đua.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showAppAlert(context, 'Lỗi', 'Không thể từ chối lời mời.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lời mời',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_items == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingShimmer(height: 160),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jockey Invites', style: context.typography.h2.copyWith(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Review and manage your upcoming race invitations from stable owners.', style: context.typography.bodyMuted.copyWith(fontSize: 16)),
            ],
          ),
        ),
        
        Expanded(
          child: _items!.isEmpty
            ? const EmptyState(
                icon: Icons.mail_outline,
                title: 'Không có lời mời',
                subtitle: 'Bạn hiện không có lời mời thi đấu nào.',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _items!.length,
                itemBuilder: (context, index) {
                  final invite = _items![index];
                  final isPending = invite.status.toLowerCase() == 'pending';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Status, Race Name, Image
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPending ? 'PENDING INVITE' : _translateStatus(invite.status).toUpperCase(),
                                      style: context.typography.caption.copyWith(
                                        color: isPending ? context.colors.accent : context.colors.muted,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      invite.horseName,
                                      style: context.typography.h3.copyWith(fontSize: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 14, color: context.colors.muted),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ERMS Tournament', // Dummy location based on HTML
                                          style: context.typography.bodyMuted.copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Horse Image Box
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1598974357801-cbca100e65d3?auto=format&fit=crop&q=80&w=200'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Stable Owner Info Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.surface2.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.colors.accent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person, color: context.colors.accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'STABLE OWNER',
                                        style: context.typography.caption.copyWith(fontSize: 10, letterSpacing: 1.2),
                                      ),
                                      Text(
                                        'ERMS Equine Stables', // Dummy owner name based on HTML
                                        style: context.typography.body.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Action Buttons
                          if (isPending) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleAccept(invite.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Text('ACCEPT', style: context.typography.label.copyWith(color: Colors.white, letterSpacing: 1.2)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.red.withValues(alpha: 0.1),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleReject(invite.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 18),
                                              const SizedBox(width: 8),
                                              Text('REJECT', style: context.typography.label.copyWith(color: Colors.red.shade400, letterSpacing: 1.2)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
        ),
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
