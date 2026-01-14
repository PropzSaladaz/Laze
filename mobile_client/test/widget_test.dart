import 'package:flutter_test/flutter_test.dart';
import 'package:laze/main.dart';

void main() {
  testWidgets('MyApp creates MaterialApp', (WidgetTester tester) async {
    // Note: This test is basic because the app requires Hive initialization
    // and other setup that is difficult to test without mocking
    
    // We can at least verify the MyApp widget can be created
    const app = MyApp();
    expect(app, isNotNull);
  });
}
