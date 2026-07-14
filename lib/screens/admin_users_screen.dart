import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUser>? _items;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.api
        .getAdminUsers()
        .then((items) {
          if (mounted) setState(() => _items = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _items = []);
        });
  }

  List<AdminUser> get _filtered {
    if (_items == null) return [];
    if (_searchQuery.isEmpty) return _items!;
    final q = _searchQuery.toLowerCase();
    return _items!
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.role.value.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý thành viên',
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              style: context.typography.body,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành viên…',
                prefixIcon: Icon(Icons.search, size: 18, color: context.colors.muted),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_items == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LoadingShimmer(height: 72),
        ),
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Không tìm thấy thành viên',
        subtitle: 'Thử điều chỉnh lại từ khóa tìm kiếm.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text('Có ${filtered.length} thành viên', style: context.typography.bodyMuted),
              ],
            ),
          );
        }
        final user = filtered[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(name: user.name, role: user.role.value, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      RoleBadge(role: user.role.value),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: context.colors.muted),
                  onPressed: () => _showChangeRoleDialog(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeRoleDialog(AdminUser user) {
    if (user.role == Role.admin) {
      showAppAlert(context, 'Cảnh báo', 'Không thể thay đổi quyền Admin.', isError: true);
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text('Chọn vai trò mới', style: context.typography.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Role.values.where((r) => r != Role.admin).map((r) {
              return ListTile(
                title: Text(r.value, style: context.typography.body),
                trailing: r == user.role
                    ? Icon(Icons.check, color: context.colors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (r != user.role) {
                    _changeRole(user, r);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _changeRole(AdminUser user, Role newRole) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await widget.api.updateUserRole(user.id, newRole.value);
      if (!mounted) return;
      Navigator.pop(context); // close progress
      
      final items = await widget.api.getAdminUsers();
      if (!mounted) return;
      
      setState(() => _items = items);
      await showAppAlert(context, 'Thành công', 'Đã cấp quyền ${newRole.value} cho ${user.name}');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress
      await showAppAlert(context, 'Thất bại', 'Không thể đổi quyền', isError: true);
    }
  }
}
