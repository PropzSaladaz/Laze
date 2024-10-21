import 'package:flutter/material.dart';
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorConstants.background),
        scaffoldBackgroundColor: ColorConstants.background,
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