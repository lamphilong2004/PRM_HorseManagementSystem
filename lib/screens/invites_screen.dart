import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool _loading = false;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _handleAccept(String inviteId) async {
    try {
      await widget.api.acceptInvitation(inviteId);
      if (!mounted) return;
      await showAppAlert(context, 'Thành công 🎉', 'Đã chấp nhận lời mời đua.');
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
      title: 'Lời mời của tôi',
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Web-like Header Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1A10B981), // Emerald green tint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x3310B981)),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lời Mời Của Tôi',
                      style: context.typography.h1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quản lý các yêu cầu mời điều khiển ngựa từ các chủ ngựa khác. Phản hồi nhanh chóng để không bỏ lỡ cơ hội tham gia các giải đua đỉnh cao.',
                      style: context.typography.bodyMuted.copyWith(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _items == null || _items!.isEmpty
              ? const EmptyState(
                  icon: Icons.mail_outline_rounded,
                  title: 'Không có lời mời',
                  subtitle: 'Bạn hiện không có lời mời thi đấu nào.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _items!.length,
                  itemBuilder: (context, index) {
                    final invite = _items![index];
                    final isPending = invite.status.toLowerCase() == 'pending';
                    final isAccepted = invite.status.toLowerCase() == 'accepted';
                    final isRejected = invite.status.toLowerCase() == 'rejected';
                    final isCancelled = invite.status.toLowerCase() == 'cancelled';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Owner info & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'TỪ CHỦ NGỰA: ',
                                        style: context.typography.captionUpper.copyWith(
                                          fontSize: 11,
                                          color: context.colors.muted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          (invite.ownerName ?? 'Horse Owner').toUpperCase(),
                                          style: context.typography.body.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: context.colors.text,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(context, invite.status),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Horse Name Row
                            Row(
                              children: [
                                const Text(
                                  '🐎',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  invite.horseName,
                                  style: context.typography.h3.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: context.colors.border),
                            const SizedBox(height: 16),

                            // Details Grid (Two columns)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailItem(
                                        context,
                                        label: '📅 GIẢI ĐUA',
                                        value: invite.raceName ?? 'Chưa cập nhật',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDetailItem(
                                        context,
                                        label: '🐴 NGỰA',
                                        value: '${invite.horseBreed ?? 'Nice'} - ${invite.horseWeight ?? 450}kg',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailItem(
                                        context,
                                        label: '📏 CỰ LY',
                                        value: invite.raceDistance != null ? '${invite.raceDistance}m' : '1000m',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDetailItem(
                                        context,
                                        label: '✉️ LỜI NHẮN',
                                        value: invite.message != null && invite.message!.isNotEmpty
                                            ? '"${invite.message}"'
                                            : '"Mời bạn cưỡi ngựa của tôi"',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Bottom actions based on status
                            if (isPending) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _handleAccept(invite.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ĐỒNG Ý',
                                                  style: context.typography.label.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
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
                                        border: Border.all(color: const Color(0x33EF4444)),
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0x1AEF4444),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _handleReject(invite.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'TỪ CHỐI',
                                                  style: context.typography.label.copyWith(
                                                    color: const Color(0xFFEF4444),
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isAccepted) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final date = invite.raceScheduledAt;
                                      if (date != null && date.isNotEmpty) {
                                        context.push('/jockey-schedule?date=${Uri.encodeComponent(date)}');
                                      } else {
                                        context.push('/jockey-schedule');
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Xem lịch thi đấu  >',
                                            style: context.typography.label.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (isCancelled || isRejected) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: context.isDark ? const Color(0x1AFF5555) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.isDark ? const Color(0x33FF5555) : const Color(0xFFFCA5A5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.block_flipped,
                                      color: context.isDark ? const Color(0xFFFFAAAA) : const Color(0xFFDC2626),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isCancelled ? 'Cuộc đua đã có Jockey khác' : 'Yêu cầu đã bị từ chối',
                                      style: TextStyle(
                                        color: context.isDark ? const Color(0xFFFFAAAA) : const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildDetailItem(BuildContext context, {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.captionUpper.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colors.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.typography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final (bg, fg, border, text) = switch (status.toLowerCase()) {
      'accepted' => (
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
          const Color(0xFFA7F3D0),
          'Đã đồng ý',
        ),
      'rejected' => (
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
          const Color(0xFFFCA5A5),
          'Đã từ chối',
        ),
      'cancelled' => (
          const Color(0xFFFFE4E6),
          const Color(0xFF9F1239),
          const Color(0xFFFECDD3),
          'Đã chốt Jockey khác',
        ),
      _ => (
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
          const Color(0xFFFDE68A),
          'Đang chờ',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
