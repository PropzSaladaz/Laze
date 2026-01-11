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

### Running Locally Before Push

To ensure your changes pass CI:

```bash
# Test Rust
cd controller_server
cargo build
cargo test --lib

# Test Flutter
cd ../mobile_client
flutter pub get
flutter test
flutter build apk --release
```

## Adding New Tests

### Rust

Add tests in a `mod tests` block at the end of your file:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_something() {
        // Your test here
    }
}
```

### Flutter

Create a new test file in the `test/` directory mirroring your source structure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_client/your_module.dart';

void main() {
  group('YourClass', () {
    test('does something', () {
      // Your test here
    });
  });
}
```

## Best Practices

1. **Write tests before fixing bugs** - Reproduce the bug in a test first
2. **Keep tests focused** - One concept per test
3. **Use descriptive test names** - Make failures easy to understand
4. **Mock external dependencies** - Don't rely on network, filesystem, or display
5. **Run tests before committing** - Ensure all tests pass locally

## Known Issues

- Some Rust tests require X11 display (marked with `#[ignore]`)
- Flutter widget tests may require additional mocking for Hive initialization

## Future Improvements

- Add integration tests for server-client communication
- Add widget tests for Flutter UI components
- Set up code coverage reporting
- Add performance benchmarks
