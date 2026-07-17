import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../core/services/wallet_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({
    super.key,
    required this.api,
    required this.walletService,
  });

  final ApiService api;
  final WalletService walletService;

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final _betController = TextEditingController();
  final _searchController = TextEditingController();

  List<Prediction> _predictions = [];
  List<Tournament> _tournaments = [];
  List<Race> _races = [];
  List<RaceHorse> _horses = [];

  String _selectedTournamentId = 'all';
  String? _selectedRaceId;
  String? _selectedHorseId;
  bool? _predictionOpen;
  int _predictedPosition = 1;
  String _statusFilter = 'ALL';
  bool _sortNewest = true;
  String _searchText = '';

  bool _loadingHorses = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _betController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {});

    try {
      final List<Prediction> history = await widget.api.getPredictions().catchError((_) => <Prediction>[]);
      final List<Tournament> tournamentList = await widget.api.getTournaments().catchError((_) => <Tournament>[]);
      final List<Race> raceList = await widget.api.getRaces().catchError((_) => <Race>[]);

      // Only show scheduled or ongoing races for new predictions
      final nextRaces = raceList.where((race) => 
        ['SCHEDULED', 'ONGOING', 'LIVE', 'RUNNING', 'PENDING'].contains(race.status.toUpperCase())
      ).toList();

      if (mounted) {
        setState(() {
          _predictions = history;
          _tournaments = tournamentList;
          _races = nextRaces;
        });

        if (_selectedRaceId == null && nextRaces.isNotEmpty) {
          _selectRace(nextRaces.first.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _selectRace(String raceId) async {
    setState(() {
      _selectedRaceId = raceId;
      _predictionOpen = null;
      _horses = [];
      _selectedHorseId = null;
      _predictedPosition = 1;
      _loadingHorses = true;
    });

    try {
      final openStatus = await widget.api.checkRaceOpenForPrediction(raceId).catchError((_) => {'isOpen': false});
      final horseList = await widget.api.getRaceHorses(raceId).catchError((_) => <RaceHorse>[]);

      final race = _races.firstWhere((item) => item.id == raceId, orElse: () => _races.first);
      final fallbackOpen = race.status.toUpperCase() == 'SCHEDULED';

      if (mounted && _selectedRaceId == raceId) {
        setState(() {
          _horses = horseList;
          _predictionOpen = openStatus['isOpen'] is bool ? openStatus['isOpen'] as bool : fallbackOpen;
          _loadingHorses = false;
        });
      }
    } catch (e) {
      if (mounted && _selectedRaceId == raceId) {
        setState(() => _loadingHorses = false);
      }
    }
  }

  Future<void> _submitPrediction() async {
    if (_selectedRaceId == null || _selectedHorseId == null) {
      await showAppAlert(context, 'Thiếu thông tin', 'Vui lòng chọn cuộc đua và chiến mã.', isError: true);
      return;
    }
    if (_predictionOpen != true) {
      await showAppAlert(context, 'Dự đoán đã đóng', 'Cuộc đua này hiện không nhận dự đoán.', isError: true);
      return;
    }

    final betVal = int.tryParse(_betController.text.replaceAll(',', '')) ?? 0;
    if (betVal <= 0) {
      await showAppAlert(context, 'Mức cược chưa hợp lệ', 'Vui lòng nhập số điểm cược lớn hơn 0.', isError: true);
      return;
    }

    if (widget.walletService.balance < betVal) {
      await showAppAlert(
        context, 
        'Không đủ điểm', 
        'Số dư hiện tại của bạn là ${NumberFormat.decimalPattern('vi-VN').format(widget.walletService.balance)} điểm.',
        isError: true
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.api.placePrediction(
        raceId: _selectedRaceId!,
        horseId: _selectedHorseId!,
        betAmount: betVal,
        predictedPosition: _predictedPosition,
      );

      await widget.walletService.deductBalance(betVal);

      if (mounted) {
        final horse = _horses.firstWhere((h) => h.id == _selectedHorseId);
        await showAppAlert(
          context, 
          'Đặt dự đoán thành công 🎉', 
          'Chiến mã: ${horse.name}\nMức cược: ${NumberFormat.decimalPattern('vi-VN').format(betVal)} điểm'
        );
        
        setState(() {
          _betController.clear();
          _selectedHorseId = null;
        });
        
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        await showAppAlert(context, 'Thất bại', 'Có lỗi xảy ra khi đặt dự đoán.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  List<Race> _getVisibleRaces() {
    if (_selectedTournamentId == 'all') {
      return _races;
    }
    return _races.where((race) => race.tournamentId == _selectedTournamentId).toList();
  }

  List<Prediction> _getFilteredHistory() {
    final query = _searchText.trim().toLowerCase();
    final list = _predictions.where((p) {
      final statusMatch = _statusFilter == 'ALL' || p.status.toUpperCase() == _statusFilter;
      final nameMatch = query.isEmpty ||
          (p.raceName ?? '').toLowerCase().contains(query) ||
          (p.pickedHorseName).toLowerCase().contains(query);
      return statusMatch && nameMatch;
    }).toList();

    list.sort((a, b) {
      // Sort mock
      return _sortNewest ? 1 : -1; 
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final totalBet = _predictions.fold<int>(0, (sum, p) => sum + (p.betAmount ?? 0).toInt());
    final wonCount = _predictions.where((p) => p.status.toUpperCase() == 'WON').length;
    // fallback payout / prize
    final totalPayout = _predictions.fold<int>(0, (sum, p) => sum + (p.prizeAmount ?? 0).toInt());

    final visibleRaces = _getVisibleRaces();
    final filteredHistory = _getFilteredHistory();

    return AppScaffold(
      title: 'Dự đoán',
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatTile('Số dư', NumberFormat.decimalPattern('vi-VN').format(widget.walletService.balance), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Đã cược', NumberFormat.decimalPattern('vi-VN').format(totalBet), Colors.amber)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatTile('Thắng', '$wonCount lượt', const Color(0xFF10B981))),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Thưởng', NumberFormat.decimalPattern('vi-VN').format(totalPayout), Colors.purple)),
              ],
            ),
            const SizedBox(height: 20),

            // Form section
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đặt dự đoán mới', style: context.typography.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: 16),

                  // Tournament Filter Dropdown
                  Text('GIẢI ĐẤU', style: context.typography.captionUpper),
                  const SizedBox(height: 8),
                  _buildTournamentDropdown(),
                  const SizedBox(height: 16),

                  // Races List
                  Text('CUỘC ĐUA ĐANG MỞ DỰ ĐOÁN', style: context.typography.captionUpper),
                  const SizedBox(height: 8),
                  if (visibleRaces.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: context.radii.base,
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Text('Không có cuộc đua nào đang mở dự đoán.', style: context.typography.bodyMuted),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: visibleRaces.length,
                        itemBuilder: (context, index) {
                          final race = visibleRaces[index];
                          final active = _selectedRaceId == race.id;
                          return GestureDetector(
                            onTap: () => _selectRace(race.id),
                            child: Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: active ? Colors.blue.withValues(alpha: 0.05) : context.colors.surface,
                                borderRadius: context.radii.base,
                                border: Border.all(color: active ? Colors.blue : context.colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(race.status.toUpperCase(), style: TextStyle(color: active ? Colors.blue : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                      if (active) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(race.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('${race.distance}m - ${race.maxHorses} chiến mã', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Status Info Box
                  if (_selectedRaceId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.border.withValues(alpha: 0.2),
                        borderRadius: context.radii.base,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trạng thái nhận cược', style: TextStyle(fontSize: 12)),
                              Text(
                                _predictionOpen == true ? 'Đang mở' : 'Đã đóng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _predictionOpen == true ? const Color(0xFF10B981) : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Horses list
                  if (_selectedRaceId != null && _predictionOpen == true) ...[
                    Text('CHỌN CHIẾN MÃ', style: context.typography.captionUpper),
                    const SizedBox(height: 8),
                    if (_loadingHorses)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (_horses.isEmpty)
                      Text('Cuộc đua chưa có chiến mã.', style: context.typography.bodyMuted)
                    else
                      ..._horses.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final horse = entry.value;
                        final active = _selectedHorseId == horse.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedHorseId = horse.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF10B981).withValues(alpha: 0.05) : context.colors.surface,
                              borderRadius: context.radii.base,
                              border: Border.all(color: active ? const Color(0xFF10B981) : context.colors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFF10B981) : context.colors.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${idx + 1}', style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(horse.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('Nài ngựa: ${horse.jockeyName ?? "Chưa rõ"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (active) const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                  ],

                  // Bet Amount & Predicted Rank Input Row
                  if (_selectedHorseId != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ĐIỂM CƯỢC', style: context.typography.captionUpper),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _betController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Nhập điểm cược',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TOP DỰ ĐOÁN', style: context.typography.captionUpper),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _predictedPosition,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: List.generate(10, (idx) {
                                  final pos = idx + 1;
                                  return DropdownMenuItem(
                                    value: pos,
                                    child: Text('$pos', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  );
                                }),
                                onChanged: (val) => setState(() => _predictedPosition = val ?? 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Bets Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickChip('Tối thiểu', () => _betController.text = '100000'),
                          _buildQuickChip('Tất cả', () => _betController.text = widget.walletService.balance.toString()),
                          _buildQuickChip('100K', () => _betController.text = '100000'),
                          _buildQuickChip('200K', () => _betController.text = '200000'),
                          _buildQuickChip('500K', () => _betController.text = '500000'),
                          _buildQuickChip('1M', () => _betController.text = '1000000'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    AppButton(
                      label: 'Xác nhận đặt dự đoán',
                      isLoading: _submitting,
                      onPressed: _submitPrediction,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // History Section
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lịch sử dự đoán', style: context.typography.h2.copyWith(fontSize: 18)),
                      GestureDetector(
                        onTap: () => setState(() => _sortNewest = !_sortNewest),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: context.colors.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                          child: Text(_sortNewest ? 'Mới nhất' : 'Cũ nhất', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchText = val),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo trận đấu hoặc ngựa',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status chips filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'PENDING', 'WON', 'LOST', 'OPEN', 'CLOSED'].map((status) {
                        final active = _statusFilter == status;
                        return GestureDetector(
                          onTap: () => setState(() => _statusFilter = status),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? Colors.blue : context.colors.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'ALL' ? 'Tất cả' : status,
                              style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // History Items List
                  if (filteredHistory.isEmpty)
                    const EmptyState(
                      icon: Icons.history_toggle_off,
                      title: 'Không có dữ liệu',
                      subtitle: 'Hãy đặt dự đoán hoặc đổi bộ lọc.',
                    )
                  else
                    ...filteredHistory.map((p) {
                      final statusVariant = StatusBadge.fromStatus(p.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: context.radii.base,
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.raceName?.isNotEmpty == true ? p.raceName! : 'Trận đấu ${p.raceId.substring(0, 8)}…',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(label: p.status, variant: statusVariant),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Chiến mã: ${p.pickedHorseName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 12),
                            Container(height: 1, color: context.colors.border),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('VỊ TRÍ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('Hạng ${p.predictedPosition ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MỨC CƯỢC', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('${NumberFormat.decimalPattern('vi-VN').format(p.betAmount ?? 0)} điểm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('THƯỞNG', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${NumberFormat.decimalPattern('vi-VN').format(p.prizeAmount ?? 0)} điểm',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTournamentDropdown() {
    final list = [
      const DropdownMenuItem(value: 'all', child: Text('Tất cả giải đấu')),
      ..._tournaments.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
    ];
    return DropdownButtonFormField<String>(
      initialValue: _selectedTournamentId,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: list,
      onChanged: (val) {
        setState(() {
          _selectedTournamentId = val ?? 'all';
          _selectedRaceId = null;
          _predictionOpen = null;
          _horses = [];
          _selectedHorseId = null;
        });
        final visible = _getVisibleRaces();
        if (visible.isNotEmpty) {
          _selectRace(visible.first.id);
        }
      },
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
