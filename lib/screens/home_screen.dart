import 'dart:ui';
import 'package:flutter/material.dart';

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
import 'spectator/predictions_screen.dart';
import 'spectator/race_results_screen.dart';
import 'races_screen.dart';
import 'referee_races_screen.dart';
import 'tournaments_screen.dart';
import 'jockey_schedule_screen.dart';
import 'spectator/livestream_screen.dart';
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
  _NavItem(routeName: 'Tournaments',    label: 'Giải đấu',    icon: Icons.emoji_events_outlined,       activeIcon: Icons.emoji_events),
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
  List<Tournament>? _tournaments;
  List<Race>? _races;

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
      final profileData = await widget.auth.apiService.getMyProfile();
      final user = profileData['user'] ?? profileData;
      if (user != null && user.containsKey('profile')) {
        final profileMap = user['profile'];
        if (profileMap is Map && profileMap.containsKey('points')) {
          final points = int.tryParse(profileMap['points'].toString()) ?? 0;
          await widget.walletService.setBalance(points);
        }
      }
    } catch (_) {}
  }

  void _fetchData() {
    if (widget.auth.session?.user.role == Role.spectator) {
      _runAutoClaim();
    }
    Future.wait([
      widget.auth.apiService.getTournaments(),
      widget.auth.apiService.getRaces(),
    ]).then((results) {
      if (mounted) {
        setState(() {
          _tournaments = results[0] as List<Tournament>;
          _races = results[1] as List<Race>;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _tournaments = [];
          _races = [];
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppBackground(
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
                            title: Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                fontFamily: context.typography.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: context.colors.text,
                              ),
                            ),
                            leading: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.text),
                              onPressed: () => Navigator.pop(context),
                            ),
                            bottom: PreferredSize(
                              preferredSize: const Size.fromHeight(1),
                              child: Container(
                                height: 1,
                                color: context.isDark ? context.colors.border : const Color(0x1F000000),
                              ),
                            ),
                          ),
                          body: ProfileScreen(
                            auth: widget.auth,
                            walletService: widget.walletService,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: UserAvatar(
                    name: user.name,
                    role: user.role.value,
                    size: 32,
                  ),
                ),
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
      'Tournaments'    => TournamentsScreen(api: api, role: widget.auth.session?.user.role),
      'Races'          => RacesScreen(api: api, role: widget.auth.session?.user.role),
      'Livestream'     => LiveStreamScreen(api: api),
      'Predictions'    => PredictionsScreen(api: api, walletService: widget.walletService),
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

  String _roleLabel(Role role) {
    return switch (role) {
      Role.spectator => 'Khán giả',
      Role.owner => 'Chủ ngựa',
      Role.jockey => 'Jockey',
      Role.referee => 'Trọng tài',
      Role.admin => 'Quản trị',
    };
  }

  Widget _buildHomeDashboard(BuildContext context, User user) {
    final bool isSpectator = user.role == Role.spectator;
    final bool isOwner = user.role == Role.owner;
    final bool isJockey = user.role == Role.jockey;

    // Filter public tournaments
    final activeTournaments = (_tournaments ?? []).take(3).toList();

    // Filter open races
    final openRaces = (_races ?? []).where((r) => 
      ['SCHEDULED', 'ONGOING', 'LIVE', 'PENDING'].contains(r.status.toUpperCase())
    ).take(5).toList();

    // Live count
    final liveCount = (_races ?? []).where((r) => 
      ['ONGOING', 'LIVE', 'RUNNING'].contains(r.status.toUpperCase())
    ).length;

    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Greeting & Role header
          Text(
            'Dashboard',
            style: context.typography.h1.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Xin chào, ${user.name} • ${_roleLabel(user.role)}',
            style: context.typography.bodyMuted,
          ),
          const SizedBox(height: 16),

          if (isSpectator) ...[
            // Virtual Points Wallet Card (Expo Blue Card style)
            _buildWalletCard(context),
            const SizedBox(height: 16),

            // StatTiles Row (Trophy, Flag, Radio icons)
            Row(
              children: [
                Expanded(child: _buildStatTile(context, Icons.emoji_events_rounded, 'Giải mở', '${activeTournaments.length}', Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile(context, Icons.flag_rounded, 'Đua mở', '${openRaces.length}', const Color(0xFF10B981))),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile(context, Icons.radio_button_checked_rounded, 'Live', '$liveCount', const Color(0xFFF43F5E))),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Access Grid ("Truy cập nhanh")
            Text('Truy cập nhanh', style: context.typography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            _buildQuickAccessGrid(context),
            const SizedBox(height: 24),

            // Featured Tournaments ("Giải đấu nổi bật")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giải đấu nổi bật', style: context.typography.h2.copyWith(fontSize: 18)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentsScreen(api: widget.auth.apiService)));
                  },
                  child: const Text('Xem tất cả', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeTournaments.isEmpty)
              _buildEmptyState('Chưa có giải đang hoạt động', Icons.emoji_events_outlined)
            else
              ...activeTournaments.map((t) => _buildTournamentCard(context, t)),
            const SizedBox(height: 16),

            // Predictable Races ("Cuộc đua có thể dự đoán")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cuộc đua có thể dự đoán', style: context.typography.h2.copyWith(fontSize: 18)),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 3);
                  },
                  child: const Text('Đặt cược', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (openRaces.isEmpty)
              _buildEmptyState('Chưa có cuộc đua mở dự đoán', Icons.flag_outlined)
            else
              ...openRaces.map((r) => _buildRaceCard(context, r)),
          ] else ...[
            // Non-spectator Tasks
            Text('Tác vụ chính', style: context.typography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            ..._buildNonSpectatorTasks(context, isOwner, isJockey),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.walletService,
      builder: (context, _) {
        final balanceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'Điểm');
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.primary, context.colors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(28),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SỐ DƯ ĐIỂM ẢO', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      balanceFormatter.format(widget.walletService.balance),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Dùng để đặt dự đoán trong các cuộc đua đang mở.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    final api = widget.auth.apiService;
    final shortcuts = [
      _ShortcutItem('Giải đấu', Icons.emoji_events_rounded, Colors.blue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentsScreen(api: api)));
      }),
      _ShortcutItem('Cuộc đua', Icons.flag_rounded, Colors.amber.shade700, () {
        setState(() => _selectedIndex = 1);
      }),
      _ShortcutItem('Dự đoán', Icons.analytics_rounded, const Color(0xFF10B981), () {
        setState(() => _selectedIndex = 3);
      }),
      _ShortcutItem('Bảng hạng', Icons.military_tech_rounded, Colors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => RaceResultsScreen(api: api)));
      }),
      _ShortcutItem('Livestream', Icons.radio_rounded, const Color(0xFFF43F5E), () {
        setState(() => _selectedIndex = 2);
      }),
      _ShortcutItem('Thông báo', Icons.notifications_rounded, Colors.grey.shade700, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(api: api)));
      }),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: shortcuts.map((s) => GestureDetector(
        onTap: s.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(t.location.isNotEmpty ? t.location : 'Chưa rõ địa điểm', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Text(
                'Giải đấu',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(t.startDate)),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceCard(BuildContext context, Race r) {
    return GestureDetector(
      onTap: () {
        if (r.status.toUpperCase() == 'ONGOING') {
          setState(() => _selectedIndex = 2);
        } else {
          setState(() => _selectedIndex = 3);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(r.scheduledAt)),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.status.toUpperCase(),
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildNonSpectatorTasks(BuildContext context, bool isOwner, bool isJockey) {
    final api = widget.auth.apiService;
    final List<Widget> list = [];
    
    list.add(_buildTaskCard(
      context,
      'Xem Giải Đấu',
      'Khám phá các giải đấu đua ngựa đang diễn ra, xem chi tiết lịch thi đấu và bảng xếp hạng thành tích.',
      Icons.emoji_events_rounded,
      Colors.blue,
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentsScreen(api: api))),
    ));
    
    list.add(_buildTaskCard(
      context,
      'Xem Cuộc Đua',
      'Cập nhật danh sách cuộc đua, cự ly, thời gian xuất phát và diễn biến kết quả thi đấu.',
      Icons.flag_rounded,
      Colors.amber.shade700,
      () => setState(() => _selectedIndex = 1),
    ));
    
    if (isOwner) {
      list.add(_buildTaskCard(
        context,
        'Ngựa Của Tôi',
        'Quản lý đội ngựa thi đấu cá nhân, đăng ký tham gia vòng đua mới và gửi lời mời thuê Jockey.',
        Icons.pets_rounded,
        const Color(0xFF10B981),
        () => setState(() => _selectedIndex = 2),
      ));
    }
    
    if (isJockey) {
      list.add(_buildTaskCard(
        context,
        'Lời Mời Của Tôi',
        'Xem và phản hồi yêu cầu điều khiển ngựa từ chủ ngựa, sau đó theo dõi lịch trình nhận việc.',
        Icons.mail_rounded,
        const Color(0xFF10B981),
        () => setState(() => _selectedIndex = 2),
      ));
    }
    
    return list;
  }
  
  Widget _buildTaskCard(BuildContext context, String label, String desc, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ShortcutItem {
  _ShortcutItem(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
