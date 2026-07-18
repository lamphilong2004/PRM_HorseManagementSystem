import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class OwnerHorsesTab extends StatefulWidget {
  const OwnerHorsesTab({super.key, required this.api});
  final ApiService api;

  @override
  State<OwnerHorsesTab> createState() => _OwnerHorsesTabState();
}

class _OwnerHorsesTabState extends State<OwnerHorsesTab> {
  List<Horse>? _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _items = null);
    widget.api.getHorses().then((items) {
      if (mounted) setState(() => _items = items);
    }).catchError((_) {
      if (mounted) setState(() => _items = []);
    });
  }

  void _deleteHorse(Horse horse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Xoá chiến mã?', style: context.typography.h3),
        content: Text('Bạn có chắc chắn muốn xoá ${horse.name}? Hành động này không thể hoàn tác.', style: context.typography.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Xoá', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await widget.api.deleteHorse(horse.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá chiến mã')));
        _reload();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showHorseDialog({Horse? horse}) {
    final isEdit = horse != null;
    final nameCtrl = TextEditingController(text: horse?.name);
    final breedCtrl = TextEditingController(text: horse?.breed);
    final ageCtrl = TextEditingController(text: horse?.age?.toString());
    final weightCtrl = TextEditingController(text: horse?.weight?.toString());
    final colorCtrl = TextEditingController(text: horse?.color);
    final genderCtrl = TextEditingController(text: horse?.gender);
    final originCtrl = TextEditingController(text: horse?.origin);
    bool isLoading = false;

    Widget buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          style: context.typography.body,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: context.typography.caption,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.primary),
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(isEdit ? 'Sửa thông tin' : 'Đăng ký ngựa mới', style: context.typography.h3),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildTextField(nameCtrl, 'Tên chiến mã'),
                        buildTextField(breedCtrl, 'Giống ngựa'),
                        buildTextField(ageCtrl, 'Tuổi'),
                        buildTextField(weightCtrl, 'Cân nặng (kg)'),
                        buildTextField(colorCtrl, 'Màu sắc'),
                        buildTextField(genderCtrl, 'Giới tính'),
                        buildTextField(originCtrl, 'Xuất xứ'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên ngựa')));
                            return;
                          }
                          setDialogState(() => isLoading = true);
                          try {
                            final data = {
                              'name': nameCtrl.text.trim(),
                              'breed': breedCtrl.text.trim(),
                              'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
                              'weight': double.tryParse(weightCtrl.text.trim()) ?? 0.0,
                              'color': colorCtrl.text.trim(),
                              'gender': genderCtrl.text.trim().toUpperCase(),
                              'origin': originCtrl.text.trim(),
                              'healthCertUrl': 'https://example.com/no-cert-provided.pdf',
                            };
                            if (isEdit) {
                              await widget.api.updateHorse(horse.id, data);
                            } else {
                              await widget.api.createHorse(data);
                            }
                            if (ctx.mounted) {
                              HapticFeedback.lightImpact();
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Cập nhật thành công!' : 'Đăng ký ngựa thành công!')),
                              );
                              await Future.delayed(const Duration(milliseconds: 300));
                              _reload();
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Lưu thay đổi' : 'Đăng ký', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHorseDialog(),
        backgroundColor: context.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final horse = _items![index];
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
                          style: context.typography.body.copyWith(fontWeight: FontWeight.w600, color: context.colors.text),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: context.colors.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Mã: ${horse.id.length > 8 ? horse.id.substring(0, 8) : horse.id}…',
                                style: context.typography.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: context.colors.muted, size: 20),
                        onPressed: () => _showHorseDialog(horse: horse),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteHorse(horse),
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
