import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/models/app_models.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';

class RefereeReportScreen extends StatefulWidget {
  const RefereeReportScreen({
    super.key,
    required this.api,
    required this.race,
  });

  final ApiService api;
  final Race race;

  @override
  State<RefereeReportScreen> createState() => _RefereeReportScreenState();
}

class _RefereeReportScreenState extends State<RefereeReportScreen> {
  List<Map<String, dynamic>> _horses = [];
  bool _loading = true;
  bool _submitting = false;

  // horseId -> position string ("1", "2", "3", "DNF" etc)
  final Map<String, String> _positions = {};
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHorses();
  }

  Future<void> _loadHorses() async {
    try {
      final data = await widget.api.getRefereeRaceHorses(widget.race.id);
      if (mounted) {
        setState(() {
          _horses = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _horses = [];
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Biên bản trận đấu',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.race.name, style: context.typography.h1),
        const SizedBox(height: 6),
        Text(
          'Vui lòng điền thứ hạng thực tế cho từng chiến mã tham gia. Trận đấu chỉ có thể đóng và tổng kết khi có biên bản kết quả.',
          style: context.typography.bodyMuted,
        ),
        const SizedBox(height: 24),
        
        Text('Danh sách nài ngựa và ngựa', style: context.typography.h2),
        const SizedBox(height: 12),
        if (_horses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Không có dữ liệu chiến mã nào tham gia.'),
          )
        else
          ..._horses.map(_buildHorseRow),
        
        const SizedBox(height: 24),
        Text('Ghi chú của trọng tài', style: context.typography.label),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: context.typography.body,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú thêm (nếu có)...',
            filled: true,
            fillColor: context.isDark ? const Color(0x0AFFFFFF) : context.colors.surface2,
            border: OutlineInputBorder(
              borderRadius: context.radii.base,
              borderSide: BorderSide(color: context.colors.border),
            ),
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Xác nhận Kết Quả',
          icon: Icons.check_circle_outline,
          isLoading: _submitting,
          onPressed: _horses.isEmpty ? null : _submitResults,
        ),
      ],
    );
  }

  Widget _buildHorseRow(Map<String, dynamic> item) {
    final horseId = item['horseId']?.toString() ?? '';
    final horseName = item['horse']?['name']?.toString() ?? 'Ngựa vô danh';
    final jockeyName = item['jockeyName']?.toString() ?? 'Chưa rõ';

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
                  Text(horseName, style: context.typography.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Nài ngựa: $jockeyName', style: context.typography.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                initialValue: _positions[horseId],
                hint: const Text('Hạng'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: context.radii.sm,
                  ),
                ),
                items: [
                  ...List.generate(10, (i) => DropdownMenuItem(
                    value: '${i + 1}',
                    child: Text('Hạng ${i + 1}'),
                  )),
                  const DropdownMenuItem(
                    value: 'DNF',
                    child: Text('Bỏ cuộc'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _positions[horseId] = val);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitResults() async {
    // Validate that all horses have a position
    if (_positions.length < _horses.length) {
      await showAppAlert(context, 'Thiếu thông tin', 'Vui lòng chọn hạng cho tất cả chiến mã.', isError: true);
      return;
    }

    // Build rankings array
    final rankings = _positions.entries.map((e) {
      final posStr = e.value;
      return {
        'horseId': e.key,
        'position': posStr == 'DNF' ? 99 : int.parse(posStr),
      };
    }).toList();

    setState(() => _submitting = true);
    try {
      await widget.api.confirmRaceResult(
        widget.race.id,
        rankings,
        _notesController.text,
      );
      if (!mounted) return;
      await showAppAlert(context, 'Thành công', 'Đã lưu biên bản kết quả trận đấu.');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await showAppAlert(context, 'Lỗi', 'Không thể lưu kết quả. $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
