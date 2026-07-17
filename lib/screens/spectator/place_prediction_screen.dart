import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../core/services/wallet_service.dart';
import '../../ui/app_theme.dart';
import 'package:intl/intl.dart';
import '../../ui/app_widgets.dart';

class PlacePredictionScreen extends StatefulWidget {
  const PlacePredictionScreen({super.key, required this.api, required this.walletService});

  final ApiService api;
  final WalletService walletService;

  @override
  State<PlacePredictionScreen> createState() => _PlacePredictionScreenState();
}

class _PlacePredictionScreenState extends State<PlacePredictionScreen> {
  final _betController = TextEditingController();

  List<Race> _races = [];
  String? _selectedRaceId;
  bool? _isOpen;
  List<RaceHorse> _horses = [];
  String? _selectedHorseId;
  int? _predictedPosition;
  bool _loading = false;
  bool _loadingHorses = false;

  @override
  void initState() {
    super.initState();
    widget.api
        .getRaces()
        .then((items) {
          if (mounted) setState(() => _races = items);
        })
        .catchError((_) {
          if (mounted) setState(() => _races = []);
        });
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Đặt dự đoán',
      resizeToAvoidBottomInset: true,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStepCard(
            step: 1,
            title: 'Chọn trận đua',
            child: _buildRaceList(),
          ),
          if (_selectedRaceId != null && _isOpen == false) ...[
            const SizedBox(height: 16),
            _buildClosedBanner(),
          ],
          if (_selectedRaceId != null && _isOpen == true && _horses.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStepCard(
              step: 2,
              title: 'Chọn chiến mã',
              child: _buildHorseList(),
            ),
            if (_selectedHorseId != null) ...[
              const SizedBox(height: 16),
              _buildStepCard(
                step: 3,
                title: 'Dự đoán vị trí về đích',
                child: _buildPositionList(),
              ),
            ],
            const SizedBox(height: 16),
            _buildStepCard(
              step: _selectedHorseId != null ? 4 : 3,
              title: 'Số tiền đặt cược',
              child: _buildBetInput(),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
          if (_loadingHorses) ...[
            const SizedBox(height: 16),
            const LoadingShimmer(height: 120),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đặt dự đoán', style: context.typography.h1),
        const SizedBox(height: 6),
        Text(
          'Chọn một trận đấu và ngựa đua, sau đó nhập số tiền đặt cược.',
          style: context.typography.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required Widget child,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.primary.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: TextStyle(
                      fontFamily: context.typography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: context.typography.h3),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: context.colors.border),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRaceList() {
    if (_races.isEmpty) {
      return const LoadingShimmer(height: 80);
    }
    return Column(
      children: _races.map((race) {
        final statusVariant = StatusBadge.fromStatus(race.status);
        return SelectableItemRow(
          title: race.name,
          subtitle: race.status,
          trailing: StatusBadge(label: race.status, variant: statusVariant),
          selected: _selectedRaceId == race.id,
          onTap: () => _selectRace(race.id),
        );
      }).toList(),
    );
  }

  Widget _buildHorseList() {
    return Column(
      children: _horses.map((horse) {
        return SelectableItemRow(
          title: horse.name,
          selected: _selectedHorseId == horse.id,
          onTap: () => setState(() => _selectedHorseId = horse.id),
        );
      }).toList(),
    );
  }

  Widget _buildPositionList() {
    return DropdownButtonFormField<int>(
      initialValue: _predictedPosition,
      decoration: InputDecoration(
        hintText: 'Chọn vị trí',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: context.radii.base,
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: context.radii.base,
          borderSide: BorderSide(color: context.colors.border),
        ),
      ),
      dropdownColor: context.colors.surface,
      items: List.generate(10, (index) {
        final pos = index + 1;
        return DropdownMenuItem(
          value: pos,
          child: Text(
            'Vị trí thứ $pos',
            style: context.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      }),
      onChanged: (val) => setState(() => _predictedPosition = val),
    );
  }

  Widget _buildBetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hạn mức (100.000 – 10.000,000)', style: context.typography.bodyMuted),
            ListenableBuilder(
              listenable: widget.walletService,
              builder: (context, _) => Text(
                'Ví: ${NumberFormat.compact().format(widget.walletService.balance)}',
                style: context.typography.bodyMuted.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _betController,
          keyboardType: TextInputType.number,
          style: context.typography.body,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '500,000',
            prefixIcon: Icon(Icons.attach_money_rounded,
                size: 18, color: context.colors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.dangerLight,
        borderRadius: context.radii.base,
        border: Border.all(color: context.colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: context.colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trận đấu này đã đóng, không thể đặt dự đoán.',
              style: TextStyle(
                fontFamily: context.typography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = !_loading &&
        _selectedHorseId != null &&
        _predictedPosition != null &&
        _betController.text.isNotEmpty;

    return AppButton(
      label: 'Đặt dự đoán',
      icon: Icons.check_circle_outline,
      isLoading: _loading,
      onPressed: canSubmit ? _handlePlace : null,
    );
  }

  void _selectRace(String raceId) {
    setState(() {
      _selectedRaceId = raceId;
      _isOpen = null;
      _horses = [];
      _selectedHorseId = null;
      _predictedPosition = null;
      _loadingHorses = true;
    });

    widget.api.checkRaceOpenForPrediction(raceId).then((data) {
      if (mounted && _selectedRaceId == raceId) {
        setState(() => _isOpen = data['isOpen'] == true);
      }
    }).catchError((_) {});

    widget.api.getRaceHorses(raceId).then((items) {
      if (mounted && _selectedRaceId == raceId) {
        setState(() {
          _horses = items;
          _loadingHorses = false;
        });
      }
    }).catchError((_) {
      if (mounted && _selectedRaceId == raceId) {
        setState(() => _loadingHorses = false);
      }
    });
  }

  Future<void> _handlePlace() async {
    if (_selectedRaceId == null ||
        _selectedHorseId == null ||
        _predictedPosition == null ||
        _betController.text.isEmpty) {
      await showAppAlert(context, 'Thiếu thông tin', 'Vui lòng điền đầy đủ các thông tin.', isError: true);
      return;
    }

    final bet = int.tryParse(_betController.text) ?? 0;
    if (bet < 100000 || bet > 10000000) {
      await showAppAlert(context, 'Sai hạn mức', 'Tiền cược phải nằm trong khoảng từ 100k đến 10M.', isError: true);
      return;
    }

    if (bet > widget.walletService.balance) {
      await showAppAlert(context, 'Số dư không đủ', 'Bạn chỉ còn ${NumberFormat.currency(locale: 'vi_VN', symbol: 'Điểm').format(widget.walletService.balance)} trong ví.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.api.placePrediction(
        raceId: _selectedRaceId!,
        horseId: _selectedHorseId!,
        betAmount: bet,
        predictedPosition: _predictedPosition,
      );
      
      await widget.walletService.deductBalance(bet);
      
      if (!mounted) return;
      await showAppAlert(context, 'Thành công! 🎉', 'Dự đoán của bạn đã được đặt.');
      setState(() {
        _selectedRaceId = null;
        _selectedHorseId = null;
        _predictedPosition = null;
        _isOpen = null;
        _horses = [];
        _betController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Đặt dự đoán thất bại.';
      await showAppAlert(context, 'Lỗi', message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
