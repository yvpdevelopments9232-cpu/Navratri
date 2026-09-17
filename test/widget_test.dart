import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:navratri/main.dart';
import 'package:navratri/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const NavratriMandalApp(),
      ),
    );
    expect(find.byType(NavratriMandalApp), findsOneWidget);
  });
}
