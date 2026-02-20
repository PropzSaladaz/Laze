import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    print("Key event: ${event.logicalKey.keyLabel}");
    return false;
  });
}
