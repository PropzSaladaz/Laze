import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:laze/config/dependencies.dart';
import 'package:laze/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/home/widgets/home_screen.dart';
import 'package:laze/presentation/onboarding/onboarding_screen.dart';
import 'package:laze/presentation/settings/settings_screen.dart';
import 'package:laze/presentation/core/themes/app_theme.dart';
import 'package:laze/services/app_service_wrapper.dart';
import 'package:laze/services/theme_notifier.dart';
import 'package:provider/provider.dart';

void setupLogging() {
  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
    }
  });
}

void main() async {
  setupLogging();

  // Hive needs WidgetsBinding to be initialized for platform channel access
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait by default — fullscreen mousepad unlocks rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter("shortcuts_data");
  // register Hive adapters
  Hive.registerAdapter(ShortcutDataAdapter());

  // Await for all repository services
  final repositoryService = await RepositoryService.initializeLocal();
  final themeNotifier = await ThemeNotifier.create(
    repositoryService.deviceSettingsRepository,
  );
  final onboardingCompleted = await repositoryService
      .deviceSettingsRepository
      .getOnboardingCompleted();

  runApp(
    MultiProvider(
      providers: [
        ...repositoryService.providers,
        ChangeNotifierProvider<AppServiceWrapper>(
          create: (context) => AppServiceWrapper(
            deviceSettings: Provider.of<DeviceSettingsRepository>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
      ],
      child: MyApp(showOnboarding: !onboardingCompleted),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'Laze - Desktop Controller',
      theme: AppTheme.light,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 10),
      themeAnimationCurve: Curves.easeOutCubic,
      debugShowCheckedModeBanner: false,
      initialRoute: showOnboarding ? '/onboarding-first-run' : '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/onboarding-first-run': (context) => const OnboardingScreen(),
        '/onboarding': (context) => const OnboardingScreen(replay: true),
      },
    );
  }
}
