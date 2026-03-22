# Testing Guide

This document describes the testing infrastructure for the Mobile Virtual Device project.

## Controller Server (Rust)

### Running Tests

```bash
cd controller_server
cargo test
```

### Test Structure

- **Unit Tests**: Located in `src/` files alongside the code they test
- **Test Modules**:
  - `src/actions.rs`: Tests for action decoding and serialization
  - `src/server/tests.rs`: Tests for server commands and configuration
  - `src/mobile_controller.rs`: Tests for controller functionality (some require X11)

### Test Coverage

- Action decoding (keyboard, mouse, scroll, text)
- Server request/response serialization
- Command structures
- Configuration handling

### Note

Some tests require X11 display and are marked with `#[ignore]`. To run all tests including ignored ones:

```bash
cargo test -- --ignored
```

## Mobile Client (Flutter)

### Running Tests

```bash
cd mobile_client
flutter test
```

### Test Structure

- **Unit Tests**: Located in `test/` directory
- **Test Files**:
  - `test/utils/result_test.dart`: Tests for Result type utility
  - `test/domain/shortcut_test.dart`: Tests for Shortcut model
  - `test/data/new_client_response_test.dart`: Tests for DTO serialization
  - `test/widget_test.dart`: Basic widget tests

### Test Coverage

- Result type (Ok/Error handling)
- Shortcut model creation and validation
- DTO serialization/deserialization
- Basic widget creation

## Continuous Integration

The project uses GitHub Actions for CI/CD:

### Workflows

1. **Full CI** (`ci.yml`): Runs on every push/PR
   - Builds and tests both Rust and Flutter components
   
2. **Rust CI** (`rust-ci.yml`): Runs on controller_server changes
   - Builds controller_server
   - Runs all Rust tests
   - Optional: Format check and clippy
   
3. **Flutter CI** (`flutter-ci.yml`): Runs on mobile_client changes
   - Gets Flutter dependencies
   - Runs all Flutter tests
   - Builds Android APK
   - Optional: Format check and analyze
