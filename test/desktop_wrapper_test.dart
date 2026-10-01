import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navratri/providers/display_mode_provider.dart';
import 'package:navratri/widgets/desktop_wrapper.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DesktopWrapper mounts and auto-fits on mobile screen width in Desktop Mode', (WidgetTester tester) async {
    // Set mobile phone screen size (390 x 844 dp)
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final displayModeProvider = DisplayModeProvider(initialMode: DisplayMode.desktop);

    await tester.pumpWidget(
      ChangeNotifierProvider<DisplayModeProvider>.value(
        value: displayModeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: DesktopWrapper(
              minWidth: 1050,
              child: SizedBox(
                width: 1050,
                height: 800,
                child: Text('Desktop Content on Android'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify DesktopWrapper and child rendered
    expect(find.byType(DesktopWrapper), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Desktop Content on Android'), findsOneWidget);
    expect(find.byType(IconButton), findsWidgets); // Floating zoom controls
  });

  testWidgets('DesktopWrapper bypasses canvas and zoom controls in Mobile Mode (Dairy Management style)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final displayModeProvider = DisplayModeProvider(initialMode: DisplayMode.mobile);

    await tester.pumpWidget(
      ChangeNotifierProvider<DisplayModeProvider>.value(
        value: displayModeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: DesktopWrapper(
              minWidth: 1050,
              child: SizedBox(
                width: 1050,
                height: 800,
                child: Text('Mobile Native Content'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // In Mobile mode: InteractiveViewer and zoom toolbar are bypassed
    expect(find.byType(DesktopWrapper), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Mobile Native Content'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
