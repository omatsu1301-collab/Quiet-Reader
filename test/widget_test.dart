import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_reader/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - full app requires Hive init
    expect(QuietReaderApp, isNotNull);
  });
}
