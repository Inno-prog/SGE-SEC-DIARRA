import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/constants/app_constants.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client
  await ApiClient().initialize();

  await initializeDateFormatting('fr_FR', null);
  final prefs = await SharedPreferences.getInstance();
  final lastLocation = prefs.getString('last_location') ?? AppRoutes.dashboard;
  runApp(
    ProviderScope(
      overrides: [
        lastLocationProvider.overrideWith((ref) => lastLocation),
      ],
      child: const SGEApp(),
    ),
  );
}

class SGEApp extends ConsumerWidget {
  const SGEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return _LocationSaver(
      child: _ThemeSaver(
        child: _EmployeeIdFixer(
          child: MaterialApp.router(
            title: AppConstants.baseAppName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: router,
            locale: const Locale('fr', 'FR'),
          ),
        ),
      ),
    );
  }
}

class _LocationSaver extends ConsumerWidget {
  final Widget child;
  const _LocationSaver({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String>(lastLocationProvider, (previous, next) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_location', next);
    });
    return child;
  }
}

class _ThemeSaver extends ConsumerStatefulWidget {
  final Widget child;
  const _ThemeSaver({required this.child});

  @override
  ConsumerState<_ThemeSaver> createState() => _ThemeSaverState();
}

class _ThemeSaverState extends ConsumerState<_ThemeSaver> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('theme_mode');
    if (saved != null && saved >= 0 && saved <= 2) {
      final mode = ThemeMode.values[saved];
      if (mounted && mode != ref.read(themeModeProvider)) {
        ref.read(themeModeProvider.notifier).state = mode;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ThemeMode>(themeModeProvider, (previous, next) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', next.index);
    });
    return widget.child;
  }
}

class _EmployeeIdFixer extends ConsumerWidget {
  final Widget child;
  const _EmployeeIdFixer({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}
