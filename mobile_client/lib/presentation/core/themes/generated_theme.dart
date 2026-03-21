// GENERATED — Source: tokens.json
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color fg;
  final Color surface_1;
  final Color surface_2;
  final Color surface_3;
  final Color text;
  final Color textMuted;
  final Color textInverse;
  final Color muted;
  final Color border;
  final Color divider;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color link;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color error;
  final Color onError;
  final Color hover;
  final Color active;
  final Color focus;
  final Color disabledBg;
  final Color disabledFg;
  final Color disabledBorder;
  final Color overlay;
  final Color shadowHigh;
  final Color shadowLow;

  const AppColors({
    required this.bg,
    required this.fg,
    required this.surface_1,
    required this.surface_2,
    required this.surface_3,
    required this.text,
    required this.textMuted,
    required this.textInverse,
    required this.muted,
    required this.border,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.link,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.error,
    required this.onError,
    required this.hover,
    required this.active,
    required this.focus,
    required this.disabledBg,
    required this.disabledFg,
    required this.disabledBorder,
    required this.overlay,
    required this.shadowHigh,
    required this.shadowLow,
  });

  @override
  AppColors copyWith({
    Color? bg,
    Color? fg,
    Color? surface_1,
    Color? surface_2,
    Color? surface_3,
    Color? text,
    Color? textMuted,
    Color? textInverse,
    Color? muted,
    Color? border,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? link,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? error,
    Color? onError,
    Color? hover,
    Color? active,
    Color? focus,
    Color? disabledBg,
    Color? disabledFg,
    Color? disabledBorder,
    Color? overlay,
    Color? shadowHigh,
    Color? shadowLow,
  }) => AppColors(
        bg: bg ?? this.bg,
        fg: fg ?? this.fg,
        surface_1: surface_1 ?? this.surface_1,
        surface_2: surface_2 ?? this.surface_2,
        surface_3: surface_3 ?? this.surface_3,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        textInverse: textInverse ?? this.textInverse,
        muted: muted ?? this.muted,
        border: border ?? this.border,
        divider: divider ?? this.divider,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        secondary: secondary ?? this.secondary,
        onSecondary: onSecondary ?? this.onSecondary,
        link: link ?? this.link,
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        error: error ?? this.error,
        onError: onError ?? this.onError,
        hover: hover ?? this.hover,
        active: active ?? this.active,
        focus: focus ?? this.focus,
        disabledBg: disabledBg ?? this.disabledBg,
        disabledFg: disabledFg ?? this.disabledFg,
        disabledBorder: disabledBorder ?? this.disabledBorder,
        overlay: overlay ?? this.overlay,
        shadowHigh: shadowHigh ?? this.shadowHigh,
        shadowLow: shadowLow ?? this.shadowLow,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      surface_1: Color.lerp(surface_1, other.surface_1, t)!,
      surface_2: Color.lerp(surface_2, other.surface_2, t)!,
      surface_3: Color.lerp(surface_3, other.surface_3, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      active: Color.lerp(active, other.active, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      disabledBg: Color.lerp(disabledBg, other.disabledBg, t)!,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t)!,
      disabledBorder: Color.lerp(disabledBorder, other.disabledBorder, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadowHigh: Color.lerp(shadowHigh, other.shadowHigh, t)!,
      shadowLow: Color.lerp(shadowLow, other.shadowLow, t)!,
    );
  }
}

@immutable
class DesignScale extends ThemeExtension<DesignScale> {
  final double space2xs;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double space2xl;
  final double space3xl;
  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  const DesignScale({
    required this.space2xs,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.space2xl,
    required this.space3xl,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
  });

  @override
  DesignScale copyWith({
    double? space2xs,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? space2xl,
    double? space3xl,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
  }) => DesignScale(
        space2xs: space2xs ?? this.space2xs,
        spaceXs: spaceXs ?? this.spaceXs,
        spaceSm: spaceSm ?? this.spaceSm,
        spaceMd: spaceMd ?? this.spaceMd,
        spaceLg: spaceLg ?? this.spaceLg,
        spaceXl: spaceXl ?? this.spaceXl,
        space2xl: space2xl ?? this.space2xl,
        space3xl: space3xl ?? this.space3xl,
        radiusXs: radiusXs ?? this.radiusXs,
        radiusSm: radiusSm ?? this.radiusSm,
        radiusMd: radiusMd ?? this.radiusMd,
        radiusLg: radiusLg ?? this.radiusLg,
        radiusXl: radiusXl ?? this.radiusXl,
        radiusPill: radiusPill ?? this.radiusPill,
      );

  @override
  DesignScale lerp(ThemeExtension<DesignScale>? other, double t) {
    if (other is! DesignScale) return this;
    return DesignScale(
      space2xs: _lerpDouble(space2xs, other.space2xs, t)!,
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: _lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: _lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: _lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t)!,
      space2xl: _lerpDouble(space2xl, other.space2xl, t)!,
      space3xl: _lerpDouble(space3xl, other.space3xl, t)!,
      radiusXs: _lerpDouble(radiusXs, other.radiusXs, t)!,
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: _lerpDouble(radiusXl, other.radiusXl, t)!,
      radiusPill: _lerpDouble(radiusPill, other.radiusPill, t)!,
    );
  }
}

double? _lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0; b ??= 0.0;
  return a * (1.0 - t) + b * t;
}
