import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import 'package:flutter/services.dart';

class OwnerTournamentRegistrationSheet extends StatefulWidget {
  const OwnerTournamentRegistrationSheet({
    super.key,
    required this.api,
    required this.tournament,
  });

  final ApiService api;
  final Tournament tournament;

  @override
  State<OwnerTournamentRegistrationSheet> createState() => _SheetState();
}

class _SheetState extends State<OwnerTournamentRegistrationSheet> {
  List<Horse>? _horses;
  String? _selectedHorseId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final horses = await widget.api.getHorses();
      if (mounted) {
        setState(() {
          _horses = horses;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _horses = [];
        });
      }
    }
  }

  void _submit() async {
    if (_selectedHorseId == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.api.registerHorseForTournament(
        widget.tournament.id,
        _selectedHorseId!,
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký giải đấu thành công!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_horses == null) {
      return Container(
        height: 200,
        color: context.colors.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
            Text('Đăng ký giải đấu', style: context.typography.h2),
            const SizedBox(height: 8),
            Text(
              'Giải đấu: ${widget.tournament.name}',
              style: context.typography.bodyMuted,
            ),
            const SizedBox(height: 24),
            
            Text('Chọn Chiến Mã', style: context.typography.captionUpper),
            const SizedBox(height: 8),
            if (_horses!.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Center(
                  child: Text('Bạn chưa có ngựa nào để đăng ký.', style: context.typography.bodyMuted),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _horses!.length,
                  itemBuilder: (context, index) {
                    final h = _horses![index];
                    final isSelected = _selectedHorseId == h.id;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedHorseId = h.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? context.colors.primaryLight : context.colors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? context.colors.primary : context.colors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🏇', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              h.name,
                              style: context.typography.caption.copyWith(
                                color: isSelected ? context.colors.primary : context.colors.text2,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: (_selectedHorseId != null && !_isLoading)
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Xác Nhận Đăng Ký',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
