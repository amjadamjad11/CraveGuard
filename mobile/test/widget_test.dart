import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:craveguard/app/app.dart';

void main() {
  testWidgets('App starts and shows login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CraveGuardApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // App should render without crashing
    expect(find.text('CraveGuard'), findsAny);
  });
}
