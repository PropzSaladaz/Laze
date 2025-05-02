import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// - App Color
/// Defines base color apps & base dark and light color schemes
/// ------------------------------------------------------------
class AppColors {
  static const Color white = Colors.white;
  static const Color white1 = Color(0xFFF8F8F8); // background / mousepad text
  static const Color white2 = Color(0xFFF3F3F3); // scroll
  static const Color white3 = Color(0XFFEFEFEF); // border
  static const Color white4 = Color(0xFFE7E7E7); // scroll text / mainText
  
  static const Color grey1 = Color(0xFFDDDDDD); // dark text
  static const Color grey2 = Color(0xFFD1D1D1); // dark action button
  static const Color grey3 = Color(0xFFA1A1A1); // dark primary
  static const Color grey4 = Color(0xFF717171); // dark primary

  static const Color black = Colors.black;
  static const Color black1 = Color(0xFF111111);
  static const Color black2 = Color(0xFF333333);
  static const Color black3 = Color(0xFF555555);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.white1,
    onPrimary: AppColors.grey1,
    secondary: AppColors.white2,
    onSecondary: AppColors.grey4,
    surface: AppColors.white1,
    onSurface: AppColors.grey1,
    error: Colors.white,
    onError: Colors.red,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.black,
    onPrimary: AppColors.black3,
    secondary: AppColors.black1,
    onSecondary: AppColors.black3,
    surface: AppColors.black,
    onSurface: AppColors.black3,
    error: Colors.black,
    onError: Colors.red,
  );
}


/// ------------------------------------------------------------
/// - Custom Colors
/// Defines extra colors that may be used for some specific
/// cases, such as shadow colors, and more
/// ------------------------------------------------------------
class CustomColors extends ThemeExtension<CustomColors> {
  final Color shadowColorBright;
  final Color shadowColorDark;
  final Color border;

  final Color negativePrimary;
  final Color negativeOnPrimary;

  final Color negativeSecondary;
  final Color negativeOnSecondary;

  const CustomColors({
    required this.shadowColorBright, 
    required this.shadowColorDark,
    required this.border,  
    required this.negativePrimary,
    required this.negativeOnPrimary,
    required this.negativeSecondary,
    required this.negativeOnSecondary,
  });


  @override
  ThemeExtension<CustomColors> copyWith({
    Color? shadowColorBright, Color? shadowColorDark, Color? border,
    Color? negativePrimary, Color? negativeOnPrimary, Color? negativeSecondary, Color? negativeOnSecondary,}) {
    return CustomColors(
      shadowColorBright: shadowColorBright ?? this.shadowColorBright,
      shadowColorDark: shadowColorDark ?? this.shadowColorDark,
      border: border ?? this.border,
      negativePrimary: negativePrimary ?? this.negativePrimary,
      negativeOnPrimary: negativeOnPrimary ?? this.negativeOnPrimary,
      negativeSecondary: negativeSecondary ?? this.negativeSecondary,
      negativeOnSecondary: negativeOnSecondary ?? this.negativeOnSecondary,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(covariant ThemeExtension<CustomColors>? other, double t) {
    // TODO: implement lerp
    throw UnimplementedError();
  }

  // light theme
  static const light = CustomColors(
    shadowColorBright: AppColors.white,
    shadowColorDark: AppColors.grey3,
    border: AppColors.white3,
    negativePrimary: AppColors.black2,
    negativeOnPrimary: AppColors.grey2,
    negativeSecondary: AppColors.grey4,
    negativeOnSecondary: AppColors.white3,
  );  

  // dark theme
  static const dark = CustomColors(
    shadowColorBright: AppColors.black1,
    shadowColorDark: AppColors.black1,
    border: AppColors.black1,
    negativePrimary: AppColors.grey3,
    negativeOnPrimary: AppColors.white2,
    negativeSecondary: AppColors.black3,
    negativeOnSecondary: AppColors.grey3,
  );  
}