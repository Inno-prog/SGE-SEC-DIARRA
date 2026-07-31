import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized (e.g., by google-services.json plugin on Android)
  }
  try {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } catch (e) {
    // Persistence already enabled or not supported on this platform
  }
  await initializeDateFormatting('fr_FR', null);
  runApp(
    const ProviderScope(
      child: SGEApp(),
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
          title: 'SGE Secdiarra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          locale: const Locale('fr', 'FR'),
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

class _ThemeSaver extends ConsumerWidget {
  final Widget child;
  const _ThemeSaver({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ThemeMode>(themeModeProvider, (previous, next) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', next.index);
    });

    Future<void>.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('theme_mode');
      if (saved != null && saved >= 0 && saved <= 2) {
        final mode = ThemeMode.values[saved];
        if (mode != ref.read(themeModeProvider)) {
          ref.read(themeModeProvider.notifier).state = mode;
        }
      }
    });

    return child;
  }
}

class _EmployeeIdFixer extends ConsumerWidget {
  final Widget child;
  const _EmployeeIdFixer({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(ensureEmployeeIdProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) => debugPrint('employeeId fix failed: $e'),
        data: (_) => debugPrint('employeeId fix applied'),
      );
    });

    return child;
  }
}
