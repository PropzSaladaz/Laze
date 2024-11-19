import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_client/core/constants/color_constants.dart';
import 'package:mobile_client/data/model/shortcut.dart';
import 'package:mobile_client/data/state/shortcuts_provider.dart';
import 'package:mobile_client/presentation/pages/controller_screen.dart';
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
  // Some Flutter operations, like accessing platform channels, plugins, or certain services, require the binding to be initialized.
  // Hive needs this setup to be made
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter("shortcuts_data");
  // register Hive adapters
  Hive.registerAdapter(ShortcutAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return ChangeNotifierProvider<ShortcutsProvider>(
      create:(context) {
        var provider = ShortcutsProvider();
        provider.init();
        return provider;
      },
      child: MaterialApp(
        title: 'Flutter Demo',
        
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light, 
            primary: ColorConstants.background,
            onPrimary: ColorConstants.mainText, 
            secondary: ColorConstants.border, 
            onSecondary: ColorConstants.mousepadText, 
            error: Colors.red, 
            onError: Colors.black, 
            surface: ColorConstants.background, 
            onSurface: ColorConstants.mainText,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontFamily: 'NunitoSans',
          )),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ControllerScreen(),
      ),
    );
  }
}