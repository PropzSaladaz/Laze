// tools/flutter/gen_flutter.mjs
import fs from 'fs';
import path from 'path';
import {
  readTokens, ensureDir, flattenColorTokens,
  isHex, isRgba, anyColorToFlutter, banner, camel, camelCap
} from './utils.mjs';

// Map a subset to ColorScheme; the rest lives in ThemeExtension
function buildColorSchemeMap() {
  return {
    primary: 'primary',
    onPrimary: 'onPrimary',
    secondary: 'secondary',
    onSecondary: 'onSecondary',
    background: 'bg',
    onBackground: 'text',
    surface: 'surface-1',
    onSurface: 'text',
    error: 'error',
    onError: 'onError',
    surfaceVariant: 'surface-2',
    outline: 'border',
  };
}

export function generateFlutter(tokens, outDir, srcName = 'tokens.json') {
  const { color, space, radius } = tokens;
  const flat = flattenColorTokens(color);
  const mapLight = Object.fromEntries(flat.map(t => [t.name, t.light]));
  const mapDark  = Object.fromEntries(flat.map(t => [t.name, t.dark]));
  const scheme = buildColorSchemeMap();

  const dart = `${banner(srcName)}import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
${flat.map(t => `  final Color ${camel(t.name)};`).join('\n')}

  const AppColors({
${flat.map(t => `    required this.${camel(t.name)},`).join('\n')}
  });

  @override
  AppColors copyWith({
${flat.map(t => `    Color? ${camel(t.name)},`).join('\n')}
  }) => AppColors(
${flat.map(t => `        ${camel(t.name)}: ${camel(t.name)} ?? this.${camel(t.name)},`).join('\n')}
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
${flat.map(t => `      ${camel(t.name)}: Color.lerp(${camel(t.name)}, other.${camel(t.name)}, t)!,`).join('\n')}
    );
  }
}

@immutable
class DesignScale extends ThemeExtension<DesignScale> {
${Object.keys(space).map(k => `  final double space${camelCap(k)};`).join('\n')}
${Object.keys(radius).map(k => `  final double radius${camelCap(k)};`).join('\n')}

  const DesignScale({
${Object.keys(space).map(k => `    required this.space${camelCap(k)},`).join('\n')}
${Object.keys(radius).map(k => `    required this.radius${camelCap(k)},`).join('\n')}
  });

  @override
  DesignScale copyWith({
${Object.keys(space).map(k => `    double? space${camelCap(k)},`).join('\n')}
${Object.keys(radius).map(k => `    double? radius${camelCap(k)},`).join('\n')}
  }) => DesignScale(
${Object.keys(space).map(k => `        space${camelCap(k)}: space${camelCap(k)} ?? this.space${camelCap(k)},`).join('\n')}
${Object.keys(radius).map(k => `        radius${camelCap(k)}: radius${camelCap(k)} ?? this.radius${camelCap(k)},`).join('\n')}
      );

  @override
  DesignScale lerp(ThemeExtension<DesignScale>? other, double t) {
    if (other is! DesignScale) return this;
    return DesignScale(
${Object.keys(space).map(k => `      space${camelCap(k)}: _lerpDouble(space${camelCap(k)}, other.space${camelCap(k)}, t)!,`).join('\n')}
${Object.keys(radius).map(k => `      radius${camelCap(k)}: _lerpDouble(radius${camelCap(k)}, other.radius${camelCap(k)}, t)!,`).join('\n')}
    );
  }
}

double? _lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0; b ??= 0.0;
  return a * (1.0 - t) + b * t;
}
`;

  ensureDir(outDir);
  fs.writeFileSync(path.join(outDir, 'generated_theme.dart'), dart, 'utf8');
}
