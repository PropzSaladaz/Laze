import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:laze/config/dependencies.dart';
import 'package:laze/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/home/widgets/home_screen.dart';
import 'package:laze/presentation/settings/settings_screen.dart';
import 'package:laze/presentation/core/themes/app_theme.dart';
import 'package:laze/services/app_service_wrapper.dart';
import 'package:laze/services/theme_notifier.dart';
import 'package:provider/provider.dart';

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
}

void main() async {
  setupLogging();

  // Hive needs WidgetsBinding to be initialized for platform channel access
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter("shortcuts_data");
  // register Hive adapters
  Hive.registerAdapter(ShortcutDataAdapter());

  // Await for all repository services
  final repositoryService = await RepositoryService.initializeLocal();
  final themeNotifier = await ThemeNotifier.create(
    repositoryService.deviceSettingsRepository,
  );

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
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.light,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 10),
      themeAnimationCurve: Curves.easeOutCubic,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
