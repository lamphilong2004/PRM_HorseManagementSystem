import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/app_models.dart';
import '../services/wallet_service.dart';
import '../../screens/admin_scheduling_screen.dart';
import '../../screens/admin_users_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/horses_screen.dart';
import '../../screens/invites_screen.dart';
import '../../screens/leaderboard_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/place_prediction_screen.dart';
import '../../screens/predictions_screen.dart';
import '../../screens/race_results_screen.dart';
import '../../screens/races_screen.dart';
import '../../screens/referee_races_screen.dart';
import '../../screens/referee_report_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/tournaments_screen.dart';
import '../../screens/tournament_detail_screen.dart';
import '../../screens/welcome_screen.dart';
import '../../screens/jockey_schedule_screen.dart';
import '../../screens/livestream_screen.dart';
import '../../screens/profile_screen.dart';

typedef AppRouter = GoRouter;

AppRouter createAppRouter(AuthController auth, WalletService walletService) {
  return GoRouter(
    initialLocation: auth.isAuthenticated ? '/home' : '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublicRoute = path == '/' || path == '/login' || path == '/register';

      if (!auth.booted) return null;
      if (!auth.isAuthenticated && !isPublicRoute) return '/';
      if (auth.isAuthenticated && isPublicRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'Welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'Login',
        builder: (context, state) => LoginScreen(auth: auth),
      ),
      GoRoute(
        path: '/register',
        name: 'Register',
        builder: (context, state) => RegisterScreen(auth: auth),
      ),
      GoRoute(
        path: '/home',
        name: 'Home',
        builder: (context, state) => HomeScreen(auth: auth, walletService: walletService),
      ),
      GoRoute(
        path: '/tournaments',
        name: 'Tournaments',
        builder: (context, state) => TournamentsScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/tournaments/:id',
        name: 'TournamentDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TournamentDetailScreen(api: auth.apiService, tournamentId: id);
        },
      ),
      GoRoute(
        path: '/races',
        name: 'Races',
        builder: (context, state) => RacesScreen(api: auth.apiService, role: auth.session?.user.role),
      ),
      GoRoute(
        path: '/horses',
        name: 'Horses',
        builder: (context, state) => HorsesScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/invites',
        name: 'Invites',
        builder: (context, state) => InvitesScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/predictions',
        name: 'Predictions',
        builder: (context, state) => PredictionsScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/place-prediction',
        name: 'PlacePrediction',
        builder: (context, state) => PlacePredictionScreen(api: auth.apiService, walletService: walletService),
      ),
      GoRoute(
        path: '/race-results',
        name: 'RaceResults',
        builder: (context, state) => RaceResultsScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/notifications',
        name: 'Notifications',
        builder: (context, state) => NotificationsScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'Leaderboard',
        builder: (context, state) => LeaderboardScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/admin-users',
        name: 'AdminUsers',
        builder: (context, state) => AdminUsersScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/admin-scheduling',
        name: 'AdminScheduling',
        builder: (context, state) => AdminSchedulingScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/referee-races',
        name: 'RefereeRaces',
        builder: (context, state) => RefereeRacesScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/referee-report',
        name: 'RefereeReport',
        builder: (context, state) => RefereeReportScreen(api: auth.apiService, race: state.extra as Race),
      ),
      GoRoute(
        path: '/jockey-schedule',
        name: 'JockeySchedule',
        builder: (context, state) {
          final dateStr = state.uri.queryParameters['date'];
          return JockeyScheduleScreen(
            api: auth.apiService,
            initialDateStr: dateStr,
          );
        },
      ),
      GoRoute(
        path: '/livestream',
        name: 'Livestream',
        builder: (context, state) => LiveStreamScreen(api: auth.apiService),
      ),
      GoRoute(
        path: '/profile',
        name: 'Profile',
        builder: (context, state) => ProfileScreen(auth: auth, walletService: walletService),
      ),
    ],
  );
}
