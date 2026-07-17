import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import 'package:flutter/services.dart';

class OwnerRaceRegistrationSheet extends StatefulWidget {
  const OwnerRaceRegistrationSheet({
    super.key,
    required this.api,
    required this.race,
  });

  final ApiService api;
  final Race race;

  @override
  State<OwnerRaceRegistrationSheet> createState() => _SheetState();
}

class _SheetState extends State<OwnerRaceRegistrationSheet> {
  List<Horse>? _horses;
  List<Map<String, dynamic>>? _jockeys;
  String? _selectedHorseId;
  String? _selectedJockeyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final horses = await widget.api.getHorses();
      final jockeys = await widget.api.getAvailableJockeys();
      if (mounted) {
        setState(() {
          _horses = horses;
          _jockeys = jockeys;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _horses = [];
          _jockeys = [];
        });
      }
    }
  }

  void _submit() async {
    if (_selectedHorseId == null || _selectedJockeyId == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.api.registerHorseForRace(
        widget.race.id,
        _selectedHorseId!,
        _selectedJockeyId!,
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thi đấu thành công!')),
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
    if (_horses == null || _jockeys == null) {
      return Container(
        height: 300,
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
            Text('Đăng ký thi đấu', style: context.typography.h2),
            const SizedBox(height: 8),
            Text(
              'Vòng đua: ${widget.race.name}',
              style: context.typography.bodyMuted,
            ),
            const SizedBox(height: 24),
            
            Text('Chọn Chiến Mã', style: context.typography.caption),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedHorseId,
              dropdownColor: context.colors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _horses!.map((h) => DropdownMenuItem(
                value: h.id,
                child: Text(h.name, style: context.typography.body),
              )).toList(),
              onChanged: (val) => setState(() => _selectedHorseId = val),
              hint: Text('Chọn ngựa của bạn', style: context.typography.bodyMuted),
            ),
            const SizedBox(height: 16),

            Text('Mời Jockey (Kỵ Sĩ)', style: context.typography.caption),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedJockeyId,
              dropdownColor: context.colors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.colors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _jockeys!.map((j) {
                final id = j['userId'] ?? j['_id'] ?? j['id'] ?? '';
                final name = j['fullName'] ?? j['name'] ?? 'Unknown';
                return DropdownMenuItem(
                  value: id.toString(),
                  child: Text(name.toString(), style: context.typography.body),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedJockeyId = val),
              hint: Text('Chọn Jockey cho trận đấu', style: context.typography.bodyMuted),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: (_selectedHorseId != null && _selectedJockeyId != null && !_isLoading)
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
