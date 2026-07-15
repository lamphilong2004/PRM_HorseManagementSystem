import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/api_service.dart';
import '../core/auth/auth_controller.dart';
import '../core/models/app_models.dart';
import '../core/services/wallet_service.dart';
import '../main.dart'; // To access themeNotifier
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
import 'package:intl/intl.dart';

// Import sub-screens to embed dynamically
import 'admin_users_screen.dart';
import 'horses_screen.dart';
import 'invites_screen.dart';
import 'notifications_screen.dart';
import 'predictions_screen.dart';
import 'race_results_screen.dart';
import 'races_screen.dart';
import 'referee_races_screen.dart';
import 'tournaments_screen.dart';
import 'jockey_schedule_screen.dart';
import 'livestream_screen.dart';
import 'profile_screen.dart';

// ── Nav item config per role ───────────────────────────────

class _NavItem {
  const _NavItem({
    required this.routeName,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String routeName;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _spectatorNav = [
  _NavItem(routeName: 'HomeDashboard',  label: 'Trang chủ',   icon: Icons.home_outlined,              activeIcon: Icons.home),
  _NavItem(routeName: 'Races',          label: 'Cuộc đua',    icon: Icons.flag_outlined,               activeIcon: Icons.flag),
  _NavItem(routeName: 'Livestream',     label: 'Live',        icon: Icons.live_tv_outlined,            activeIcon: Icons.live_tv),
  _NavItem(routeName: 'Predictions',    label: 'Dự đoán',     icon: Icons.analytics_outlined,          activeIcon: Icons.analytics),
  _NavItem(routeName: 'Profile',        label: 'Hồ sơ',       icon: Icons.person_outline,              activeIcon: Icons.person),
];

const _ownerNav = [
  _NavItem(routeName: 'HomeDashboard',  label: 'Trang chủ',   icon: Icons.home_outlined,              activeIcon: Icons.home),
  _NavItem(routeName: 'Races',          label: 'Vòng đua',     icon: Icons.flag_outlined,               activeIcon: Icons.flag),
  _NavItem(routeName: 'Horses',         label: 'Ngựa đua',     icon: Icons.pets_outlined,               activeIcon: Icons.pets),
];

const _jockeyNav = [
  _NavItem(routeName: 'HomeDashboard',  label: 'Trang chủ',   icon: Icons.home_outlined,              activeIcon: Icons.home),
  _NavItem(routeName: 'JockeySchedule', label: 'Lịch trình',   icon: Icons.calendar_month_outlined,     activeIcon: Icons.calendar_month),
  _NavItem(routeName: 'Invites',        label: 'Lời mời',      icon: Icons.mail_outline,                activeIcon: Icons.mail),
];

const _refereeNav = [
  _NavItem(routeName: 'HomeDashboard',  label: 'Trang chủ',   icon: Icons.home_outlined,              activeIcon: Icons.home),
  _NavItem(routeName: 'Races',          label: 'Vòng đua',     icon: Icons.flag_outlined,               activeIcon: Icons.flag),
  _NavItem(routeName: 'RefereeRaces',   label: 'Trận của tôi', icon: Icons.gavel_outlined,              activeIcon: Icons.gavel),
];

const _adminNav = [
  _NavItem(routeName: 'HomeDashboard',  label: 'Trang chủ',   icon: Icons.home_outlined,              activeIcon: Icons.home),
  _NavItem(routeName: 'Races',          label: 'Vòng đua',     icon: Icons.flag_outlined,               activeIcon: Icons.flag),
  _NavItem(routeName: 'AdminUsers',     label: 'Thành viên',   icon: Icons.people_outline,              activeIcon: Icons.people),
];

List<_NavItem> _navItemsForRole(Role role) => switch (role) {
  Role.spectator => _spectatorNav,
  Role.owner     => _ownerNav,
  Role.jockey    => _jockeyNav,
  Role.referee   => _refereeNav,
  Role.admin     => _adminNav,
};

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, required this.walletService});

  final AuthController auth;
  final WalletService walletService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  List<Tournament>? _tournaments;
  List<Race>? _races;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    if (widget.auth.session?.user.role == Role.spectator) {
      _runAutoClaim();
    }
  }

  void _runAutoClaim() async {
    try {
      final predictions = await widget.auth.apiService.getPredictions();
      final settledIds = await widget.walletService.getSettledPredictionIds();
      
      for (final p in predictions) {
        if (p.status.toUpperCase() == 'WON') {
          if (!settledIds.contains(p.id)) {
            final bet = (p.betAmount ?? 0).toDouble();
            if (bet > 0) {
              final winnings = (bet * 1.8).toInt();
              await widget.walletService.addBalance(winnings);
              await widget.walletService.markPredictionAsSettled(p.id);
            }
          }
        }
      }
    } catch (_) {}
  }

  void _fetchData() {
    setState(() => _loadingData = true);
    Future.wait([
      widget.auth.apiService.getTournaments(),
      widget.auth.apiService.getRaces(),
    ]).then((results) {
      if (mounted) {
        setState(() {
          _tournaments = results[0] as List<Tournament>;
          _races = results[1] as List<Race>;
          _loadingData = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _tournaments = [];
          _races = [];
          _loadingData = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.auth.session;
    if (session == null) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final user = session.user;
    final navItems = _navItemsForRole(user.role);

    if (_selectedIndex == 0) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: context.isDark ? const Color(0x9904100C) : const Color(0xB3FFFFFF),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: _buildBrandHeader(context),
            actions: [
              IconButton(
                icon: Icon(
                  context.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: context.colors.text2,
                ),
                onPressed: () {
                  themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: context.colors.text2,
                onPressed: () => widget.auth.logout(),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: context.isDark ? context.colors.border : const Color(0x1F000000),
              ),
            ),
          ),
          body: SafeArea(
            child: _buildHomeDashboard(context, user),
          ),
          bottomNavigationBar: _buildBottomNav(context, navItems),
        ),
      );
    } else {
      // Switch screen based on the item index route
      final selectedItem = navItems[_selectedIndex];
      final childWidget = _buildChildScreen(selectedItem.routeName);

      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: childWidget,
          bottomNavigationBar: _buildBottomNav(context, navItems),
        ),
      );
    }
  }

  // ── Top header with brand ──────────────────────────

  Widget _buildBrandHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.colors.primary, context.colors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ERMS',
          style: TextStyle(
            fontFamily: context.typography.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.colors.text,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav Bar ───────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context, List<_NavItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.isDark ? context.colors.border : const Color(0x1F000000),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: navItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.label,
        )).toList(),
      ),
    );
  }

  // ── Child Screen Factory ─────────────────────────────────────

  Widget _buildChildScreen(String routeName) {
    final api = widget.auth.apiService;
    return switch (routeName) {
      'Tournaments'    => TournamentsScreen(api: api),
      'Races'          => RacesScreen(api: api),
      'Livestream'     => LiveStreamScreen(api: api),
      'Predictions'    => PredictionsScreen(api: api),
      'Profile'        => ProfileScreen(auth: widget.auth, walletService: widget.walletService),
      'RaceResults'    => RaceResultsScreen(api: api),
      'Notifications'  => NotificationsScreen(api: api),
      'Horses'         => HorsesScreen(api: api),
      'Invites'        => InvitesScreen(api: api),
      'JockeySchedule' => JockeyScheduleScreen(api: api),
      'RefereeRaces'   => RefereeRacesScreen(api: api),
      'AdminUsers'     => AdminUsersScreen(api: api),
      _                => const Center(child: Text('Đang tải...')),
    };
  }

  // ── Home Dashboard (Search Bar + Tournaments list) ───────────

  Widget _buildHomeDashboard(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user.role == Role.spectator) _buildWalletCard(context),
        _buildSearchBar(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _fetchData(),
            child: _buildDashboardContent(context, user),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.walletService,
      builder: (context, _) {
        final balanceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'Điểm');
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.primary, context.colors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SỐ DƯ ĐIỂM ẢO', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    balanceFormatter.format(widget.walletService.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0x0AFFFFFF) : context.colors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.3)),
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: context.typography.body,
          decoration: InputDecoration(
            hintText: 'Search races, tracks, or tournaments...',
            hintStyle: context.typography.bodyMuted,
            prefixIcon: Icon(Icons.search_rounded, size: 22, color: context.colors.muted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, size: 18, color: context.colors.muted),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, User user) {
    if (_loadingData && (_tournaments == null || _races == null)) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoadingShimmer(height: 120),
        ),
      );
    }

    final query = _searchQuery.toLowerCase();
    final filteredTournaments = _tournaments?.where((t) {
      final matchName = t.name.toLowerCase().contains(query);
      final matchLocation = t.location.toLowerCase().contains(query);
      
      final hasMatchingRace = _races?.any((r) => 
        r.tournamentId == t.id && r.name.toLowerCase().contains(query)
      ) ?? false;
      
      return matchName || matchLocation || hasMatchingRace;
    }).toList() ?? [];

    if (filteredTournaments.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy giải đấu',
        subtitle: 'Thử tìm kiếm bằng từ khóa khác hoặc kéo để tải lại.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredTournaments.length,
      itemBuilder: (context, index) {
        final tournament = filteredTournaments[index];
        final tournamentRaces = _races?.where((r) => 
          r.tournamentId == tournament.id && 
          (query.isEmpty || r.name.toLowerCase().contains(query) || tournament.name.toLowerCase().contains(query))
        ).toList() ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: user.role == Role.jockey
                          ? () => context.push('/tournaments/${tournament.id}')
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: context.typography.h2.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: context.colors.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tournament.location,
                                  style: context.typography.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: user.role == Role.jockey
                        ? () => context.push('/tournaments')
                        : () {},
                    child: Text('VIEW ALL', style: context.typography.caption.copyWith(color: context.colors.accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tournament Races List (Horizontal)
              if (tournamentRaces.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Không có trận đấu nào.',
                    style: context.typography.bodyMuted.copyWith(fontSize: 14),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: tournamentRaces.map((race) {
                      final isPredictable = race.status.toLowerCase() == 'open' || 
                                           race.status.toLowerCase() == 'active' || 
                                           race.status.toLowerCase() == 'scheduled';
                      
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Section
                              Stack(
                                children: [
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      color: context.colors.surface2,
                                      image: const DecorationImage(
                                        image: NetworkImage('https://images.unsplash.com/photo-1598974357801-cbca100e65d3?auto=format&fit=crop&q=80&w=800'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isPredictable ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.black45,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isPredictable) ...[
                                                Container(
                                                  width: 8, height: 8,
                                                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                _translateStatus(race.status).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: isPredictable ? Colors.greenAccent : Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Content Section
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      race.name,
                                      style: context.typography.h3.copyWith(fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Distance: 1200m • 12 Contenders',
                                      style: context.typography.bodyMuted.copyWith(fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    if (isPredictable)
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [context.colors.primary, context.colors.accent],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.colors.primary.withValues(alpha: 0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () => _showQuickPredictionDialog(context, race),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text(
                                            'DỰ ĐOÁN',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _translateStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending'   => 'Đang chờ',
      'open'      => 'Đang mở',
      'active'    => 'Hoạt động',
      'completed' => 'Hoàn thành',
      'approved'  => 'Đã duyệt',
      'confirmed' => 'Xác nhận',
      'rejected'  => 'Bị từ chối',
      'inactive'  => 'Không hoạt động',
      'cancelled' => 'Đã hủy',
      'scheduled' => 'Lên lịch',
      'ongoing'   => 'Đang diễn ra',
      'won'       => 'Thắng',
      'lost'      => 'Thua',
      _           => status,
    };
  }

  // ── Show Quick Prediction bottom sheet ────────────────────────

  void _showQuickPredictionDialog(BuildContext context, Race race) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _QuickPredictionBottomSheet(
          api: widget.auth.apiService,
          race: race,
          walletService: widget.walletService,
        );
      },
    );
  }
}

// ── Quick Prediction Bottom Sheet State ───────────────────────

class _QuickPredictionBottomSheet extends StatefulWidget {
  const _QuickPredictionBottomSheet({required this.api, required this.race, required this.walletService});

  final ApiService api;
  final Race race;
  final WalletService walletService;

  @override
  State<_QuickPredictionBottomSheet> createState() => _QuickPredictionBottomSheetState();
}

class _QuickPredictionBottomSheetState extends State<_QuickPredictionBottomSheet> {
  final _betController = TextEditingController();
  List<RaceHorse> _horses = [];
  String? _selectedHorseId;
  bool _loadingHorses = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    widget.api.getRaceHorses(widget.race.id).then((items) {
      if (mounted) {
        setState(() {
          _horses = items;
          _loadingHorses = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _horses = [];
          _loadingHorses = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1626) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1F000000),
          width: 1,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle indicator
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
            Text(
              'Dự đoán kết quả',
              style: context.typography.h2.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              widget.race.name,
              style: context.typography.bodyMuted,
            ),
            const SizedBox(height: 24),
            
            if (_loadingHorses)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_horses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Không có ngựa đua nào tham gia trận này.',
                  style: context.typography.body,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text('CHỌN NGỰA', style: context.typography.label.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                initialValue: _selectedHorseId,
                hint: Text('Chọn một chiến mã', style: context.typography.bodyMuted),
                style: context.typography.body.copyWith(color: context.colors.text),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0x0AFFFFFF) : context.colors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: context.radii.base,
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
                items: _horses.map((h) => DropdownMenuItem<String>(
                  value: h.id,
                  child: Text(h.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedHorseId = val),
              ),
              const SizedBox(height: 16),
              
              Text('MỨC CƯỢC (CREDITS)', style: context.typography.label.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _betController,
                keyboardType: TextInputType.number,
                style: context.typography.body,
                decoration: const InputDecoration(
                  hintText: '500,000',
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: context.colors.border),
                      ),
                      child: Text('CANCEL', style: TextStyle(color: context.colors.muted, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitting || _selectedHorseId == null ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SUBMIT PREDICTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final betStr = _betController.text.trim();
    if (betStr.isEmpty) {
      await showAppAlert(context, 'Thiếu thông tin', 'Vui lòng nhập số tiền cược.', isError: true);
      return;
    }
    
    final bet = int.tryParse(betStr) ?? 0;
    if (bet < 100000 || bet > 10000000) {
      await showAppAlert(context, 'Sai hạn mức', 'Tiền cược phải nằm trong khoảng từ 100k đến 10M.', isError: true);
      return;
    }

    if (bet > widget.walletService.balance) {
      await showAppAlert(context, 'Số dư không đủ', 'Bạn chỉ còn ${NumberFormat.currency(locale: 'vi_VN', symbol: 'Điểm').format(widget.walletService.balance)} trong ví.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.api.placePrediction(
        raceId: widget.race.id,
        horseId: _selectedHorseId!,
        betAmount: bet,
      );
      
      // Deduct balance locally
      await widget.walletService.deductBalance(bet);
      
      if (!mounted) return;
      Navigator.pop(context);
      await showAppAlert(context, 'Thành công 🎉', 'Dự đoán của bạn đã được đặt.');
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Không thể đặt dự đoán';
      await showAppAlert(context, 'Thất bại', message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
