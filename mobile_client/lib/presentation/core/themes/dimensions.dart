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
  static TextDim text = TextDim();
  static ButtonDim button = ButtonDim();
  static RadiusDim radius = RadiusDim();
  static SpacingDim spacing = SpacingDim();
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
  final large = 40.0;
  final medium = 28.0;
  final small = 20.0;
  final tiny = 16.0;
}

/// ------------------------------
///      Typography Dimensions
/// ------------------------------
class TextDim {
  final display = 32.0;
  final header = 22.0;
  final title = 18.0;
  final body = 16.0;
  final small = 14.0;
  final tiny = 12.0;
  final label = 13.0;
}

/// ------------------------------
///      Button Dimensions
/// ------------------------------
class ButtonDim {
  final ctaFontSize = 18.0;
  final ctaVerticalPadding = 14.0;
  final ctaHorizontalPadding = 32.0;
  final ctaIconSize = 24.0;
  
  final styledButtonBorderWidth = 4.0;
  final styledButtonMargin = 8.0;
}

/// ------------------------------
///      Radius Dimensions
/// ------------------------------
class RadiusDim {
  final large = 40.0;
  final medium = 24.0;
  final small = 16.0;
  final tiny = 8.0;
  final pill = 999.0;
}

/// ------------------------------
///      Spacing Dimensions
/// ------------------------------
class SpacingDim {
  final xl = 32.0;
  final lg = 24.0;
  final md = 16.0;
  final sm = 12.0;
  final xs = 8.0;
  final xss = 4.0;
}
