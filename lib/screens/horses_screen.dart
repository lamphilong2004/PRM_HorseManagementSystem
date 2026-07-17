import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
import 'package:flutter/services.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHorseDialog,
        backgroundColor: context.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddHorseDialog() {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final genderCtrl = TextEditingController();
    final originCtrl = TextEditingController();
    final healthCertUrlCtrl = TextEditingController();
    bool isLoading = false;

    Widget buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          style: context.typography.body,
          keyboardType: keyboardType,
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
                Text('Đăng ký ngựa mới', style: context.typography.h3),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildTextField(nameCtrl, 'Tên chiến mã'),
                        buildTextField(breedCtrl, 'Giống ngựa'),
                        buildTextField(ageCtrl, 'Tuổi', keyboardType: TextInputType.number),
                        buildTextField(weightCtrl, 'Cân nặng (kg)', keyboardType: TextInputType.number),
                        buildTextField(colorCtrl, 'Màu sắc'),
                        buildTextField(genderCtrl, 'Giới tính'),
                        buildTextField(originCtrl, 'Xuất xứ'),
                        buildTextField(healthCertUrlCtrl, 'Link giấy khám sức khỏe'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty || 
                              breedCtrl.text.trim().isEmpty ||
                              ageCtrl.text.trim().isEmpty ||
                              weightCtrl.text.trim().isEmpty ||
                              colorCtrl.text.trim().isEmpty ||
                              genderCtrl.text.trim().isEmpty ||
                              originCtrl.text.trim().isEmpty ||
                              healthCertUrlCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                            );
                            return;
                          }
                          setDialogState(() => isLoading = true);
                          try {
                            await widget.api.createHorse({
                              'name': nameCtrl.text.trim(),
                              'breed': breedCtrl.text.trim(),
                              'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
                              'weight': double.tryParse(weightCtrl.text.trim()) ?? 0.0,
                              'color': colorCtrl.text.trim(),
                              'gender': genderCtrl.text.trim(),
                              'origin': originCtrl.text.trim(),
                              'healthCertUrl': healthCertUrlCtrl.text.trim(),
                            });
                            if (ctx.mounted) {
                              HapticFeedback.lightImpact();
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              _reload();
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Đăng ký', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reload() {
    setState(() => _items = null);
    widget.api.getHorses().then((items) {
      if (mounted) setState(() => _items = items);
    }).catchError((_) {
      if (mounted) setState(() => _items = []);
    });
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
    ));
  }
}
