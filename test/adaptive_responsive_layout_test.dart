import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:navratri/core/responsive/adaptive_responsive_layout.dart';
import 'package:navratri/core/theme/app_theme.dart';
import 'package:navratri/features/auth/screens/login_screen.dart';
import 'package:navratri/features/auth/screens/sub_login_screen.dart';
import 'package:navratri/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptiveResponsiveLayout Engine Viewport Tests', () {
    testWidgets('Activates Mobile Layout on Android phone viewport (360 x 800 dp) with zero overflow',
        (WidgetTester tester) async {
      // 1. Set physical size and device pixel ratio to match 360 x 800 dp Android phone
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdaptiveResponsiveLayout(
              mobile: (ctx, constraints) => Column(
                children: const [
                  Text('MOBILE_VIEW_ACTIVE'),
                  SizedBox(height: 20),
                  Text('Phone portrait display with SafeArea and BouncingScrollPhysics'),
                ],
              ),
              tablet: (ctx, constraints) => const Text('TABLET_VIEW_ACTIVE'),
              desktop: (ctx, constraints) => const Text('DESKTOP_VIEW_ACTIVE'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify mobile tier is activated and others are not rendered
      expect(find.text('MOBILE_VIEW_ACTIVE'), findsOneWidget);
      expect(find.text('TABLET_VIEW_ACTIVE'), findsNothing);
      expect(find.text('DESKTOP_VIEW_ACTIVE'), findsNothing);

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('Activates Tablet Layout on Android tablet viewport (800 x 1280 dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdaptiveResponsiveLayout(
              mobile: (ctx, constraints) => const Text('MOBILE_VIEW_ACTIVE'),
              tablet: (ctx, constraints) => const Text('TABLET_VIEW_ACTIVE'),
              desktop: (ctx, constraints) => const Text('DESKTOP_VIEW_ACTIVE'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TABLET_VIEW_ACTIVE'), findsOneWidget);
      expect(find.text('MOBILE_VIEW_ACTIVE'), findsNothing);
      expect(find.text('DESKTOP_VIEW_ACTIVE'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Activates Desktop Layout on Windows widescreen viewport (1440 x 900 dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AdaptiveResponsiveLayout(
              mobile: (ctx, constraints) => const Text('MOBILE_VIEW_ACTIVE'),
              tablet: (ctx, constraints) => const Text('TABLET_VIEW_ACTIVE'),
              desktop: (ctx, constraints) => const Text('DESKTOP_VIEW_ACTIVE'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DESKTOP_VIEW_ACTIVE'), findsOneWidget);
      expect(find.text('MOBILE_VIEW_ACTIVE'), findsNothing);
      expect(find.text('TABLET_VIEW_ACTIVE'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Bachatgat-Identical Login & Sub-Login Viewport Verification', () {
    testWidgets('LoginScreen builds without RenderFlex overflow on Android phone (360 x 800 dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check key Bachatgat elements are present
      expect(find.text('1. Login & Authentication'), findsOneWidget);
      expect(find.text('Supabase Auth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SubLoginScreen builds without RenderFlex overflow on Android phone (360 x 800 dp)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: SubLoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Navratri Mandal Management System'), findsOneWidget);
      expect(find.text('Login & Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
