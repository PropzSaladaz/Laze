import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/controller_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
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
    );
  }
}