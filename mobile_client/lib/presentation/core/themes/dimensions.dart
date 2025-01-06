import 'package:flutter/material.dart';

final class Dimens {
  static const paddingHorizontal = 20.0;

  static const paddingVertical = 24.0;

  static const paddingScreenHorizontal = 20.0;

  static const paddingScreenVertical = 24.0;

  /// Horizontal symmetric padding for screen edges
  EdgeInsets get edgeInsetsScreenHorizontal =>
      const EdgeInsets.symmetric(horizontal: paddingScreenHorizontal);

  /// Symmetric padding for screen edges
  EdgeInsets get edgeInsetsScreenSymmetric => const EdgeInsets.symmetric(
      horizontal: paddingScreenHorizontal, vertical: paddingScreenVertical);

}