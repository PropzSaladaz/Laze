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

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: ${anyColorToFlutter(mapLight[scheme.primary])},
      onPrimary: ${anyColorToFlutter(mapLight[scheme.onPrimary])},
      secondary: ${anyColorToFlutter(mapLight[scheme.secondary])},
      onSecondary: ${anyColorToFlutter(mapLight[scheme.onSecondary])},
      background: ${anyColorToFlutter(mapLight[scheme.background])},
      onBackground: ${anyColorToFlutter(mapLight[scheme.onBackground])},
      surface: ${anyColorToFlutter(mapLight[scheme.surface])},
      onSurface: ${anyColorToFlutter(mapLight[scheme.onSurface])},
      error: ${anyColorToFlutter(mapLight[scheme.error])},
      onError: ${anyColorToFlutter(mapLight[scheme.onError])},
      surfaceVariant: ${anyColorToFlutter(mapLight[scheme.surfaceVariant])},
      outline: ${anyColorToFlutter(mapLight[scheme.outline])},
    ),
    extensions: [
      AppColors(
${flat.map(t => `        ${camel(t.name)}: ${anyColorToFlutter(mapLight[t.name])},`).join('\n')}
      ),
      DesignScale(
${Object.entries(space).map(([k,v]) => `        space${camelCap(k)}: ${Number(v)}.0,`).join('\n')}
${Object.entries(radius).map(([k,v]) => `        radius${camelCap(k)}: ${Number(v)}.0,`).join('\n')}
      ),
    ],
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: ${anyColorToFlutter(mapDark[scheme.primary])},
      onPrimary: ${anyColorToFlutter(mapDark[scheme.onPrimary])},
      secondary: ${anyColorToFlutter(mapDark[scheme.secondary])},
      onSecondary: ${anyColorToFlutter(mapDark[scheme.onSecondary])},
      background: ${anyColorToFlutter(mapDark[scheme.background])},
      onBackground: ${anyColorToFlutter(mapDark[scheme.onBackground])},
      surface: ${anyColorToFlutter(mapDark[scheme.surface])},
      onSurface: ${anyColorToFlutter(mapDark[scheme.onSurface])},
      error: ${anyColorToFlutter(mapDark[scheme.error])},
      onError: ${anyColorToFlutter(mapDark[scheme.onError])},
      surfaceVariant: ${anyColorToFlutter(mapDark[scheme.surfaceVariant])},
      outline: ${anyColorToFlutter(mapDark[scheme.outline])},
    ),
    extensions: [
      AppColors(
${flat.map(t => `        ${camel(t.name)}: ${anyColorToFlutter(mapDark[t.name])},`).join('\n')}
      ),
      DesignScale(
${Object.entries(space).map(([k,v]) => `        space${camelCap(k)}: ${Number(v)}.0,`).join('\n')}
${Object.entries(radius).map(([k,v]) => `        radius${camelCap(k)}: ${Number(v)}.0,`).join('\n')}
      ),
    ],
  );
}
`;

  ensureDir(path.join());
  fs.writeFileSync(path.join(path, 'generated_theme.dart'), dart, 'utf8');
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const input = process.argv[2];
  const out = process.argv[3] || 'flutter';
  if (!input) {
    console.error('Usage: node tools/flutter/gen_flutter.mjs <tokens.json> [outDir]');
    process.exit(1);
  }
  const tokens = readTokens(input);
  generateFlutter(tokens, out, input);
  console.log(`✅ Flutter theme written to ${out}/generated_theme.dart`);
}
