# Theming System

The project uses a centralized design token system to ensure UI consistency across the Flutter mobile app and the Tauri/Next.js desktop app.

## Overview

### Source of Truth
- **File**: `design-tokens/tokens/tokens.json`
- **Format**: JSON object defining colors, spacing, typography, etc.

### Tools
- **Location**: `tools/theming/`
- **Scripts**: Node.js scripts that transform the JSON tokens into platform-specific code.

## Usage

To regenerate themes after modifying `tokens.json`:

```bash
# Run from project root
node tools/theming/index.mjs design-tokens/tokens/tokens.json
```

## Generated Artifacts

### 1. Next.js (Desktop App)
- **Script**: `gen_next.mjs`
- **Output**: `desktop_app/src/theme/` (CSS variables or TS objects)
- **Usage**: Used by Tailwind or CSS modules.

### 2. Flutter (Mobile Client)
- **Script**: `gen_flutter.mjs`
- **Output**: `mobile_client/lib/presentation/core/themes/`
- **Usage**: Generates `ThemeData`, `AppColors` classes.

## Workflow

1. **Design**: Update token values in `design-tokens/tokens.json`.
2. **Generate**: Run the Node.js script.
3. **Verify**: Check both apps to see the visual updates.
