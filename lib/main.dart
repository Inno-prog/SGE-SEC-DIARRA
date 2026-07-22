import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'providers/providers.dart';

Future<String> _loadLastLocation() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_location') ?? AppRoutes.dashboard;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized (e.g., by google-services.json plugin on Android)
  }
  await initializeDateFormatting('fr_FR', null);
  final initialLocation = await _loadLastLocation();
  runApp(
    ProviderScope(
      overrides: [initialLocationProvider.overrideWith((_) => initialLocation)],
      child: const SGEApp(),
    ),
  );
}

class SGEApp extends ConsumerWidget {
  const SGEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);

    return _LocationSaver(
      child: MaterialApp.router(
        title: 'SGE Secdiarra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: const Locale('fr', 'FR'),
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
