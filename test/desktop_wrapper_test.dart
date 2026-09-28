import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navratri/widgets/desktop_wrapper.dart';

void main() {
  testWidgets('DesktopWrapper mounts and auto-fits on mobile screen width', (WidgetTester tester) async {
    // Set mobile phone screen size (390 x 844 dp)
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
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
    );

    await tester.pumpAndSettle();

    // Verify DesktopWrapper and child rendered
    expect(find.byType(DesktopWrapper), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Desktop Content on Android'), findsOneWidget);
    expect(find.byType(IconButton), findsWidgets); // Floating zoom controls
  });
}
