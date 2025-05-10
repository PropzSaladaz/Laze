import 'package:flutter/material.dart';

/// ------------------------------
///      Dimensions
/// ------------------------------

/// Holds all subtypes of dimensions. Use this class.
/// It serves as a namespace, and is easier to get the
/// right type from it as this is a single point of truth.
/// Avoid using the below subtypes directly
final class Dimens {
  static PaddingDim padding = PaddingDim();

  static IconDim icon = IconDim();
}

/// ------------------------------
///      Padding Dimensions
/// ------------------------------
class PaddingDim {
  final horizontal = 20.0;

  final vertical = 24.0;

  final screenHorizontal = 20.0;

  final screenVertical = 24.0;

  /// Horizontal symmetric padding for screen edges
  EdgeInsets get edgeInsetsScreenHorizontal =>
      EdgeInsets.symmetric(horizontal: screenHorizontal);

  /// Symmetric padding for screen edges
  EdgeInsets get edgeInsetsScreenSymmetric => EdgeInsets.symmetric(
      horizontal: screenHorizontal, vertical: screenVertical);
}

/// ------------------------------
///      Icon Dimensions
/// ------------------------------
class IconDim {
  final large = 45.0;
  final medium = 35.0;
  final small = 20.0;
}
