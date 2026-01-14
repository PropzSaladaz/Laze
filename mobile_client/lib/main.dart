import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:mobile_client/config/dependencies.dart';
import 'package:mobile_client/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/presentation/home/widgets/home_screen.dart';
import 'package:mobile_client/presentation/settings/settings_screen.dart';
import 'package:mobile_client/presentation/core/themes/theme.dart';
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

  // Enable edge-to-edge mode - app renders behind system navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  await Hive.initFlutter("shortcuts_data");
  // register Hive adapters
  Hive.registerAdapter(ShortcutDataAdapter());

  // Await for all repository services
  final repositoryService = await RepositoryService.initializeLocal();

  runApp(
    MultiProvider(
      providers: repositoryService.providers, 
      child: const MyApp()
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
