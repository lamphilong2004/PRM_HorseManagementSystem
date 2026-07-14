import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/api/api_client.dart';
import 'core/api/api_service.dart';
import 'core/auth/auth_controller.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_storage.dart';
import 'core/services/wallet_service.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make status bar transparent to blend with dark background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF04100C),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final sessionStorage = SessionStorage();
  final apiClient = ApiClient(sessionStorage: sessionStorage);
  final apiService = ApiService(apiClient);
  final authController = AuthController(
    apiService: apiService,
    apiClient: apiClient,
    sessionStorage: sessionStorage,
  );
  await authController.bootstrap();

  final walletService = WalletService();
  await walletService.init();

  runApp(HorseRacingApp(
    authController: authController,
    walletService: walletService,
  ));
}

// Global theme mode notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class HorseRacingApp extends StatelessWidget {
  HorseRacingApp({super.key, required this.authController, required this.walletService})
    : router = createAppRouter(authController, walletService);

  final AuthController authController;
  final WalletService walletService;
  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        // Automatically update system UI overlay style based on theme
        final isDark = currentMode == ThemeMode.dark || 
                      (currentMode == ThemeMode.system && 
                       MediaQuery.of(context).platformBrightness == Brightness.dark);
        
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF04100C) : const Color(0xFFF8FAFC),
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp.router(
          title: 'Horse Racing Tournament',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(isDark: false),
          darkTheme: buildAppTheme(isDark: true),
          themeMode: currentMode,
          routerConfig: router,
        );
      },
    );
  }
}
