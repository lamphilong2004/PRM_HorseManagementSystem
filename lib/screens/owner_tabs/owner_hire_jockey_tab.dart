import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class OwnerHireJockeyTab extends StatefulWidget {
  const OwnerHireJockeyTab({super.key, required this.api});
  final ApiService api;

  @override
  State<OwnerHireJockeyTab> createState() => _OwnerHireJockeyTabState();
}

class _OwnerHireJockeyTabState extends State<OwnerHireJockeyTab> {
  List<Registration>? _registrations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _registrations = null);
    widget.api.getOwnerRegistrations().then((items) {
      // Typically you can only hire a jockey if the registration is approved or pending
      // And we might only show those that need a jockey (though they can re-hire).
      final valid = items.where((r) => r.status.toUpperCase() != 'REJECTED').toList();
      if (mounted) setState(() => _registrations = valid);
    }).catchError((_) {
      if (mounted) setState(() => _registrations = []);
    });
  }

  void _openJockeySearch(Registration reg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JockeySearchSheet(api: widget.api, registration: reg),
    );
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
        icon: Icons.person_search_outlined,
        title: 'Chưa có ngựa thi đấu',
        subtitle: 'Bạn cần đăng ký ngựa vào giải đua trước khi thuê nài ngựa.',
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
                  Text('Thuê Nài Ngựa', style: context.typography.h1),
                  const SizedBox(height: 6),
                  Text('Tìm nài ngựa cho các chiến mã của bạn', style: context.typography.bodyMuted),
                  const SizedBox(height: 16),
                  Container(height: 1, color: context.colors.border),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }
          final reg = _registrations![index - 1];
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
                            Text('Giải: ${reg.raceName ?? 'Không rõ'}', style: context.typography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: context.colors.primary),
                      const SizedBox(width: 6),
                      Text(reg.jockeyName ?? 'Chưa có nài ngựa', style: context.typography.body.copyWith(color: reg.jockeyName == null ? Colors.redAccent : context.colors.text)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _openJockeySearch(reg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Thuê nài ngựa', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JockeySearchSheet extends StatefulWidget {
  const _JockeySearchSheet({required this.api, required this.registration});
  final ApiService api;
  final Registration registration;

  @override
  State<_JockeySearchSheet> createState() => _JockeySearchSheetState();
}

class _JockeySearchSheetState extends State<_JockeySearchSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>>? _jockeys;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.api.searchJockeys(_searchCtrl.text.trim());
      if (mounted) {
        setState(() {
          _jockeys = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _jockeys = [];
          _isLoading = false;
        });
      }
    }
  }

  void _inviteJockey(String jockeyId) async {
    try {
      await widget.api.sendJockeyInvitation(jockeyId, widget.registration.horseId, widget.registration.raceId, registrationId: widget.registration.id);
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời thành công!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text('Tìm nài ngựa', style: context.typography.h3),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              style: context.typography.body,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Nhập tên nài ngựa...',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading || _jockeys == null
                  ? const Center(child: CircularProgressIndicator())
                  : _jockeys!.isEmpty
                      ? const Center(child: Text('Không tìm thấy nài ngựa nào.'))
                      : ListView.builder(
                          itemCount: _jockeys!.length,
                          itemBuilder: (ctx, idx) {
                            final jockey = _jockeys![idx];
                            final user = jockey['user'] ?? jockey;
                            final jId = user['id'] ?? user['_id'] ?? jockey['userId'] ?? jockey['_id'];
                            final name = user['fullName'] ?? user['name'] ?? 'Không rõ tên';
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(name),
                              subtitle: Text('Weight: ${jockey['weight'] ?? '?'} kg'),
                              trailing: ElevatedButton(
                                onPressed: () => _inviteJockey(jId.toString()),
                                child: const Text('Mời'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
