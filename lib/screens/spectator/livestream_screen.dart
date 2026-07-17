import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/models/app_models.dart';
import '../../ui/app_theme.dart';
import 'package:intl/intl.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool _loading = true;
  List<Race> _races = [];
  Race? _selectedRace;

  List<dynamic> _streamHorses = [];
  bool _loadingStream = false;

  Map<String, double> _progress = {};
  List<SimulationPlan> _plans = [];
  
  String _gameState = 'countdown'; // countdown | running | finished
  int _countdown = 3;
  double _elapsed = 0.0;
  
  Timer? _countdownTimer;
  Timer? _simulationTimer;
  DateTime? _startTime;

  final List<Color> _laneColors = [
    Colors.red, Colors.blue, Colors.green, Colors.amber,
    Colors.purple, Colors.orange, Colors.pink, Colors.teal,
    Colors.lightBlue, Colors.pinkAccent
  ];

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRaces() async {
    setState(() => _loading = true);
    try {
      final races = await widget.api.getRaces();
      debugPrint('Loaded total races from API: ${races.length}');
      for (var r in races) {
        debugPrint('Race name: ${r.name}, status: ${r.status}');
      }
      if (mounted) {
        setState(() {
          _races = races.where((r) => r.status.toUpperCase() == 'ONGOING' || r.status.toUpperCase() == 'RUNNING' || r.status.toUpperCase() == 'LIVE').toList();
          debugPrint('Filtered live races count: ${_races.length}');
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error fetching races: $e');
      debugPrint('Stacktrace: $stack');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _getStreamHorseId(dynamic horse, int index) {
    if (horse is Map) {
      return horse['registrationId']?.toString() ?? horse['id']?.toString() ?? horse['_id']?.toString() ?? 'horse-$index';
    } else if (horse is RaceHorse) {
      return (horse.registrationId != null && horse.registrationId!.isNotEmpty) ? horse.registrationId! : horse.id;
    }
    return 'horse-$index';
  }

  String _getHorseName(dynamic horse) {
    if (horse is Map) {
      if (horse['horse'] is Map) return horse['horse']['name'] ?? 'Chiến mã';
      return horse['horseName'] ?? 'Chiến mã';
    } else if (horse is RaceHorse) {
      return horse.name;
    }
    return 'Chiến mã';
  }

  String _getJockeyName(dynamic horse) {
    if (horse is Map) {
      return horse['jockeyName'] ?? horse['jockey']?['user']?['fullName'] ?? 'Chưa rõ';
    } else if (horse is RaceHorse) {
      return horse.jockeyName ?? 'Chưa rõ';
    }
    return 'Chưa rõ';
  }

  List<dynamic> _buildMockHorses(int count) {
    return List.generate(count, (index) => {
      'registrationId': 'mock-reg-$index',
      'horse': {
        '_id': 'mock-horse-$index',
        'name': 'Hỏa Phong ${index + 1}',
        'breed': 'Thần Mã',
      },
      'jockeyName': 'Nài ngựa ${index + 1}',
    });
  }

  void _resetSimulation(List<dynamic> horses) {
    _countdownTimer?.cancel();
    _simulationTimer?.cancel();

    final nextProgress = <String, double>{};
    final List<SimulationPlan> rawPlans = [];
    final raceKey = _selectedRace?.id ?? 'race';

    for (int i = 0; i < horses.length; i++) {
      final id = _getStreamHorseId(horses[i], i);
      nextProgress[id] = 0.0;
      
      final stamina = seededUnit('$raceKey|$id|stamina');
      final breakSpeed = seededUnit('$raceKey|$id|break');
      final finishTime = round2(23.0 + stamina * 15.0 + breakSpeed * 4.0);
      final easing = 0.95 + seededUnit('$raceKey|$id|pace') * 0.28;

      debugPrint('SIM_DEBUG: name=${horses[i] is RaceHorse ? (horses[i] as RaceHorse).name : horses[i]}, id=$id, stamina=$stamina, breakSpeed=$breakSpeed, finishTime=$finishTime, easing=$easing');

      rawPlans.add(SimulationPlan(
        streamId: id,
        laneIndex: i,
        finishTime: finishTime,
        easing: easing,
      ));
    }

    // Sort to apply ranking adjustments
    final List<SimulationPlan> sorted = List.from(rawPlans);
    sorted.sort((a, b) {
      if (a.finishTime != b.finishTime) {
        return a.finishTime.compareTo(b.finishTime);
      }
      return a.streamId.compareTo(b.streamId);
    });

    final Map<String, SimulationPlan> finalById = {};
    for (int rankIndex = 0; rankIndex < sorted.length; rankIndex++) {
      final plan = sorted[rankIndex];
      final adjustedFinishTime = round2(plan.finishTime + rankIndex * 0.01);
      finalById[plan.streamId] = SimulationPlan(
        streamId: plan.streamId,
        laneIndex: plan.laneIndex,
        finishTime: adjustedFinishTime,
        easing: plan.easing,
      );
    }

    final List<SimulationPlan> finalPlans = rawPlans.map((plan) => finalById[plan.streamId] ?? plan).toList();

    setState(() {
      _plans = finalPlans;
      _progress = nextProgress;
      _elapsed = 0.0;
      _gameState = 'countdown';
      _countdown = 3;
    });

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          timer.cancel();
          _gameState = 'running';
          _startTime = DateTime.now();
          _startSimulation();
        }
      });
    });
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) return;
      if (_startTime == null) return;

      final elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
      final elapsedSec = elapsedMs / 1000.0;
      
      bool allFinished = true;
      final newProgress = Map<String, double>.from(_progress);
      
      for (int i = 0; i < _plans.length; i++) {
        final plan = _plans[i];
        final id = plan.streamId;
        double current = newProgress[id] ?? 0;
        
        if (current >= 100) {
          newProgress[id] = 100;
          continue;
        }
        
        allFinished = false;
        final nextValue = getProgressAtElapsed(plan, elapsedSec);
        newProgress[id] = nextValue;
      }
      
      setState(() {
        _elapsed = elapsedSec;
        _progress = newProgress;
        if (allFinished) {
          _gameState = 'finished';
          timer.cancel();
        }
      });
    });
  }

  Future<void> _loadHorsesForRace(Race race) async {
    setState(() {
      _selectedRace = race;
      _loadingStream = true;
    });
    
    try {
      final list = await widget.api.getRaceHorses(race.id);
      if (mounted) {
        final horses = (list.isNotEmpty) ? list : _buildMockHorses(6);
        setState(() {
          _streamHorses = horses;
          _loadingStream = false;
        });
        _resetSimulation(horses);
      }
    } catch (e) {
      if (mounted) {
        final mock = _buildMockHorses(6);
        setState(() {
          _streamHorses = mock;
          _loadingStream = false;
        });
        _resetSimulation(mock);
      }
    }
  }

  void _closeStream() {
    _countdownTimer?.cancel();
    _simulationTimer?.cancel();
    setState(() {
      _selectedRace = null;
      _streamHorses = [];
      _progress = {};
    });
  }

  List<Map<String, dynamic>> _getRankedHorses() {
    final list = List<Map<String, dynamic>>.generate(_streamHorses.length, (index) {
      final id = _getStreamHorseId(_streamHorses[index], index);
      final planIndex = _plans.indexWhere((p) => p.streamId == id);
      final plan = planIndex >= 0 ? _plans[planIndex] : null;
      final finished = plan != null && _elapsed >= plan.finishTime;

      return {
        'horse': _streamHorses[index],
        'id': id,
        'progress': _progress[id] ?? 0.0,
        'finished': finished,
        'finishTime': finished ? plan.finishTime.toStringAsFixed(2) : null,
        'originalIndex': index,
      };
    });
    
    list.sort((a, b) {
      final aId = a['id'];
      final bId = b['id'];
      final aPlan = _plans.firstWhere((p) => p.streamId == aId, orElse: () => SimulationPlan(streamId: aId, laneIndex: -1, finishTime: double.maxFinite, easing: 1));
      final bPlan = _plans.firstWhere((p) => p.streamId == bId, orElse: () => SimulationPlan(streamId: bId, laneIndex: -1, finishTime: double.maxFinite, easing: 1));
      
      final finishDiff = aPlan.finishTime.compareTo(bPlan.finishTime);
      if (finishDiff != 0) return finishDiff;
      return aId.compareTo(bId);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRace != null) {
      return _buildStreamModal(context);
    }

    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF04100C) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Livestream', style: context.typography.h2.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRaces,
          ),
        ],
      ),
      body: _loading && _races.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRaces,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Icon(Icons.radio_button_checked, color: Colors.pink.shade500, size: 20),
                      const SizedBox(width: 8),
                      Text('Đang live (${_races.length})', style: context.typography.h3.copyWith(color: Colors.pink.shade500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_races.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.live_tv_outlined, size: 64, color: context.colors.muted),
                          const SizedBox(height: 16),
                          Text('Chưa có cuộc đua nào đang diễn ra', style: context.typography.bodyMuted),
                        ],
                      ),
                    )
                  else
                    ..._races.map((r) => _buildRaceCard(context, r)),
                ],
              ),
            ),
    );
  }

  Widget _buildRaceCard(BuildContext context, Race race) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0x0AFFFFFF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 6),
                      Text('ĐANG LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Icon(Icons.tv, color: Colors.white70, size: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(race.name, style: context.typography.h3.copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: Text(race.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(race.scheduledAt) ?? DateTime.now()), style: context.typography.bodyMuted.copyWith(fontSize: 12)),
                Text('${race.distance}m - ${race.maxHorses} chiến mã', style: context.typography.bodyMuted.copyWith(fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadHorsesForRace(race),
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('Xem ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStreamModal(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedRace?.name ?? 'Livestream', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(_gameState == 'finished' ? 'Đã kết thúc - ${_selectedRace?.distance}m' : '${_elapsed.floor()}s - ${_selectedRace?.distance}m', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _closeStream,
                  )
                ],
              ),
            ),
            
            Expanded(
              child: _loadingStream
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text('Đang chuẩn bị đường đua...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildOvalTrack(),
                        const SizedBox(height: 20),
                        _buildLeaderboard(),
                        const SizedBox(height: 20),
                        _buildRaceInfo(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvalTrack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B), // emerald-950
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF065F46)), // emerald-800
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đường đua oval mô phỏng', style: TextStyle(color: Color(0xFFD1FAE5), fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text('LIVE SIM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: OvalTrackPainter(
                    horses: _streamHorses,
                    progress: _progress,
                    laneColors: _laneColors,
                  ),
                ),
                if (_gameState == 'countdown')
                  Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(24)),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900)),
                        const Text('Chuẩn bị xuất phát', style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _streamHorses.asMap().entries.map((e) {
                final color = _laneColors[e.key % _laneColors.length];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Làn ${e.key + 1}: ${_getHorseName(e.value)}', style: const TextStyle(color: Color(0xFFECFDF5), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final ranked = _getRankedHorses();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bảng xếp hạng live', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              Icon(Icons.emoji_events, color: Colors.amber.shade600),
            ],
          ),
          const SizedBox(height: 12),
          ...ranked.asMap().entries.map((e) {
            final index = e.key;
            final data = e.value;
            final horse = data['horse'];
            final color = _laneColors[data['originalIndex'] % _laneColors.length];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: index > 0 ? Border(top: BorderSide(color: Colors.grey.shade100)) : null),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text('#${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_getHorseName(horse), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Nài ngựa: ${_getJockeyName(horse)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(
                    data['finishTime'] != null ? '${data['finishTime']}s' : '${(data['progress'] as double).round()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ],
              ),
            );
          }),
          if (_gameState == 'finished')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: () => _resetSimulation(_streamHorses),
                icon: const Icon(Icons.replay),
                label: const Text('Mô phỏng lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRaceInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THÔNG TIN CUỘC ĐUA', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(_selectedRace?.scheduledAt ?? '') ?? DateTime.now())}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Cự ly: ${_selectedRace?.distance}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Số chiến mã: ${_streamHorses.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class OvalTrackPainter extends CustomPainter {
  final List<dynamic> horses;
  final Map<String, double> progress;
  final List<Color> laneColors;

  OvalTrackPainter({required this.horses, required this.progress, required this.laneColors});

  String _getStreamHorseId(dynamic horse, int index) {
    if (horse is Map) {
      return horse['registrationId']?.toString() ?? horse['id']?.toString() ?? horse['_id']?.toString() ?? 'horse-$index';
    } else if (horse is RaceHorse) {
      return (horse.registrationId != null && horse.registrationId!.isNotEmpty) ? horse.registrationId! : horse.id;
    }
    return 'horse-$index';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int totalHorses = horses.length;
    if (totalHorses == 0) return;

    // ViewBox mapping (800x400 to actual size)
    final double scaleX = size.width / 800;
    final double scaleY = size.height / 400;
    
    final double startX = 260 * scaleX;
    final double endX = 540 * scaleX;
    final double centerY = 200 * scaleY;
    
    final double baseRadius = (totalHorses > 12 ? 46 : 68) * scaleY;
    final double maxRadius = 170 * scaleY;
    final double laneGap = totalHorses > 1 ? min(14 * scaleY, (maxRadius - baseRadius) / (totalHorses - 1)) : 0;
    final double laneStroke = max(4 * scaleX, min(12 * scaleX, laneGap * 0.9));

    final Paint trackPaint = Paint()
      ..color = const Color(0xFF263241)
      ..style = PaintingStyle.stroke
      ..strokeWidth = laneStroke;
      
    final Paint dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scaleX;

    // Draw Tracks
    for (int i = 0; i < totalHorses; i++) {
      final double r = baseRadius + i * laneGap;
      final path = Path();
      path.moveTo(startX, centerY - r);
      path.lineTo(endX, centerY - r);
      path.arcToPoint(Offset(endX, centerY + r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(startX, centerY + r);
      path.arcToPoint(Offset(startX, centerY - r), radius: Radius.circular(r), clockwise: true);
      
      canvas.drawPath(path, trackPaint);
      
      // Simple dash by using PathMetric could be heavy, so we skip exact dash pattern for simplicity 
      // or draw a solid thin line instead if we want performance. We'll draw solid thin line.
      canvas.drawPath(path, dashPaint);
    }

    // Draw Start/Finish Line
    final Paint linePaint = Paint()..color = Colors.white..strokeWidth = 3 * scaleX;
    canvas.drawLine(Offset(startX, centerY - maxRadius - 8*scaleY), Offset(startX, centerY - baseRadius + 8*scaleY), linePaint);
    
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(text: 'START / FINISH', style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX - textPainter.width / 2, centerY - maxRadius - 24*scaleY));

    // Draw Horses
    for (int i = 0; i < totalHorses; i++) {
      final id = _getStreamHorseId(horses[i], i);
      final double value = progress[id] ?? 0.0;
      
      final double r = baseRadius + i * laneGap;
      final double straightLength = endX - startX;
      final double curveLength = pi * r;
      final double totalLength = 2 * straightLength + 2 * curveLength;
      final double d = (value / 100) * totalLength;

      double x = 0, y = 0;

      if (d <= straightLength) {
        x = startX + d;
        y = centerY - r;
      } else if (d <= straightLength + curveLength) {
        final double dCurve = d - straightLength;
        final double theta = -pi / 2 + dCurve / r;
        x = endX + r * cos(theta);
        y = centerY + r * sin(theta);
      } else if (d <= 2 * straightLength + curveLength) {
        final double dStraight = d - (straightLength + curveLength);
        x = endX - dStraight;
        y = centerY + r;
      } else {
        final double dCurve = d - (2 * straightLength + curveLength);
        final double theta = pi / 2 + dCurve / r;
        x = startX + r * cos(theta);
        y = centerY + r * sin(theta);
      }

      final color = laneColors[i % laneColors.length];
      
      final Paint horsePaint = Paint()..color = color;
      final Paint strokePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
      
      canvas.drawCircle(Offset(x, y), 13 * scaleX, horsePaint);
      canvas.drawCircle(Offset(x, y), 13 * scaleX, strokePaint);
      
      final numPainter = TextPainter(
        text: TextSpan(text: '${i + 1}', style: TextStyle(color: Colors.white, fontSize: 12 * scaleX, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr,
      );
      numPainter.layout();
      numPainter.paint(canvas, Offset(x - numPainter.width / 2, y - numPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant OvalTrackPainter oldDelegate) => true;
}

class SimulationPlan {
  final String streamId;
  final int laneIndex;
  final double finishTime;
  final double easing;

  SimulationPlan({
    required this.streamId,
    required this.laneIndex,
    required this.finishTime,
    required this.easing,
  });
}

int _multiply32(int a, int b) {
  int aLow = a & 0xFFFF;
  int aHigh = (a >> 16) & 0xFFFF;
  int bLow = b & 0xFFFF;
  int bHigh = (b >> 16) & 0xFFFF;
  
  int term1 = aLow * bLow;
  int term2 = (((aHigh * bLow) + (aLow * bHigh)) & 0xFFFF) << 16;
  return (term1 + term2) & 0xFFFFFFFF;
}

int hashString(String value) {
  int hash = 2166136261;
  for (int i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    hash = _multiply32(hash, 16777619);
  }
  return hash;
}

double seededUnit(String seed) {
  return hashString(seed) / 4294967295.0;
}

double round2(double value) {
  return (value * 100).round() / 100.0;
}

double getProgressAtElapsed(SimulationPlan plan, double elapsedSec) {
  if (elapsedSec <= 0) return 0.0;
  if (elapsedSec >= plan.finishTime) return 100.0;
  
  double t = (elapsedSec / plan.finishTime).clamp(0.0, 1.0);
  double progress = 100.0 * (1.0 - pow(1.0 - t, plan.easing));
  return progress.clamp(0.0, 99.9);
}
