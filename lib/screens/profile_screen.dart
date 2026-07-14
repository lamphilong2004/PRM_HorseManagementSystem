import 'package:flutter/material.dart';
import '../core/auth/auth_controller.dart';
import '../core/models/app_models.dart';
import '../core/services/wallet_service.dart';
import '../ui/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.auth,
    required this.walletService,
  });

  final AuthController auth;
  final WalletService walletService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<Prediction> _predictions = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    
    // Fetch profile
    try {
      final profileData = await widget.auth.apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = profileData['user'] ?? profileData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    // Fetch predictions
    try {
      final predictions = await widget.auth.apiService.getPredictions();
      if (mounted) {
        setState(() {
          _predictions = predictions;
        });
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
    }

    // Init wallet
    try {
      await widget.walletService.init();
    } catch (e) {
      debugPrint('Error init wallet: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _formatPoints(int points) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'Điểm').format(points);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.session?.user;

    if (_loading && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = _profile?['fullName'] ?? _profile?['name'] ?? user?.name ?? 'Khán giả';
    final email = _profile?['email'] ?? user?.email ?? 'Chưa cập nhật';
    final phone = _profile?['phone'] ?? 'Chưa cập nhật';

    int won = 0;
    int lost = 0;
    int totalBet = 0;
    int payout = 0;

    for (var p in _predictions) {
      if (p.status.toUpperCase() == 'WON') won++;
      if (p.status.toUpperCase() == 'LOST') lost++;
      totalBet += (p.betAmount ?? 0).toInt();
      payout += (p.prizeAmount ?? 0).toInt();
    }

    final recentPredictions = _predictions.take(5).toList();

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.account_circle, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.role.value.toUpperCase() ?? 'SPECTATOR',
                              style: TextStyle(color: Colors.blue.shade100, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: widget.walletService,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SỐ DƯ HIỆN TẠI', style: TextStyle(color: Colors.blue.shade100, fontSize: 12, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPoints(widget.walletService.balance),
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const Icon(Icons.account_balance_wallet, size: 32, color: Colors.white),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Info
            _buildSectionCard(
              context,
              title: 'Thông tin cá nhân',
              children: [
                _buildInfoRow(context, Icons.email_outlined, email),
                _buildInfoRow(context, Icons.phone_outlined, phone, isLast: true),
              ],
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(child: _buildStatTile(context, Icons.emoji_events, 'Thắng', won.toString(), Colors.teal)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatTile(context, Icons.cancel, 'Thua', lost.toString(), Colors.pink)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatTile(context, Icons.account_balance_wallet, 'Đã cược', _formatPoints(totalBet), Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatTile(context, Icons.card_giftcard, 'Thưởng', _formatPoints(payout), Colors.purple)),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Predictions
            _buildSectionCard(
              context,
              title: 'Dự đoán gần đây',
              children: recentPredictions.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Bạn chưa có lượt dự đoán nào',
                            style: context.typography.bodyMuted,
                          ),
                        ),
                      )
                    ]
                  : recentPredictions.map((p) => _buildPredictionRow(context, p, p == recentPredictions.last)).toList(),
            ),
            const SizedBox(height: 20),

            // Point restoration button removed (handled automatically by system)

            // Logout Button
            ElevatedButton(
              onPressed: () => widget.auth.logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0x0AFFFFFF) : context.colors.surface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.typography.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.muted),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: context.typography.body),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, IconData icon, String label, String value, MaterialColor color) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.shade900.withValues(alpha: 0.2) : color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? color.shade900 : color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isDark ? color.shade300 : color.shade600),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDark ? color.shade300 : color.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: context.colors.text, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(BuildContext context, Prediction p, bool isLast) {
    final raceName = p.raceName ?? 'Cuộc đua chưa xác định';
    final horseName = p.pickedHorseName.isNotEmpty ? p.pickedHorseName : 'Chiến mã số ${p.id.hashCode.toString().substring(0, 3)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  raceName,
                  style: context.typography.body.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: p.status.toUpperCase() == 'WON' ? Colors.green : (p.status.toUpperCase() == 'LOST' ? Colors.red : Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Chiến mã: $horseName', style: context.typography.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(_formatDateTime(p.createdAt != null ? DateTime.tryParse(p.createdAt!) ?? DateTime.now() : DateTime.now()), style: context.typography.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
