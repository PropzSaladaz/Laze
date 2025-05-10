import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_client/config/dependencies.dart';
import 'package:mobile_client/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/presentation/home/widgets/home_screen.dart';
import 'package:mobile_client/presentation/core/themes/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  // This is likely a mistake, as Provider will not automatically update dependents
  // when ShortcutsProvider is updated. Instead, consider changing Provider for more specific
  // implementation that handles the update mechanism, such as:

  // - ListenableProvider
  // - ChangeNotifierProvider
  // - ValueListenableProvider
  // - StreamProvider

  // Alternatively, if you are making your own provider, consider using InheritedProvider.

  // If you think that this is not an error, you can disable this check by setting
  // Provider.debugCheckInvalidValueType to `null` in your main file:
  Provider.debugCheckInvalidValueType = null;

  // responsible for connecting the Flutter framework with the underlying platform.
  // The WidgetsBinding is essential for managing the rendering pipeline, input events, and more.
  // Some Flutter operations, like accessing platform channels, plugins, or certain services,
  //require the binding to be initialized. Hive needs this setup to be made
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter("shortcuts_data");
  // register Hive adapters
  Hive.registerAdapter(ShortcutDataAdapter());

  // Await for shortcuts repo
  final repositoryService = await RepositoryService.initializeLocal();

  runApp(
    MultiProvider(providers: repositoryService.providers, child: const MyApp()),
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
      home: const HomeScreen()
    );
  }
}
