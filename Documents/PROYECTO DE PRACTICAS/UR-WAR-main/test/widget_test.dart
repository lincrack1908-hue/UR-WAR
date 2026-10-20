import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ur_war/game/widgets/virtual_joystick.dart';
import 'package:ur_war/main.dart';

void main() {
  testWidgets('UR WAR main menu smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UrWarApp());

    // Verify that the title and play button are shown.
    expect(find.text('UR WAR'), findsOneWidget);
    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);
    expect(find.text('CRÉDITOS & OPEN SOURCE'), findsOneWidget);
  });

  testWidgets(
    'Complete flow to VillageDefenseScreen and verify HUD & Joystick visibility',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const UrWarApp());
      await tester.pumpAndSettle();

      // Tap JUGAR
      await tester.tap(find.text('JUGAR'));
      await tester.pumpAndSettle();

      // On CharacterSelectScreen, tap CONTINUAR: ELEGIR MAPA
      expect(find.text('CONTINUAR: ELEGIR MAPA'), findsOneWidget);
      await tester.tap(find.text('CONTINUAR: ELEGIR MAPA'));
      await tester.pumpAndSettle();

      // On MapSelectScreen, tap ¡COMENZAR DEFENSA DE LA ALDEA!
      expect(find.text('¡COMENZAR DEFENSA DE LA ALDEA!'), findsOneWidget);
      await tester.tap(find.text('¡COMENZAR DEFENSA DE LA ALDEA!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify VillageDefenseScreen widgets
      expect(find.text('MOVER'), findsOneWidget);

      expect(find.byType(VirtualJoystick), findsNWidgets(2));
      final controls = tester.widgetList<VirtualJoystick>(
        find.byType(VirtualJoystick),
      );
      expect(controls.map((c) => c.label), contains('MOVER'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Landscape mode character select and village defense flow', (
    WidgetTester tester,
  ) async {
    // Landscape dimensions: 844 x 390
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const UrWarApp());
    await tester.pumpAndSettle();

    // Tap JUGAR
    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    // Verify landscape layout elements on CharacterSelectScreen
    expect(find.text('CONTINUAR: ELEGIR MAPA'), findsOneWidget);
    await tester.tap(find.text('CONTINUAR: ELEGIR MAPA'));
    await tester.pumpAndSettle();

    // On MapSelectScreen
    expect(find.text('¡COMENZAR DEFENSA DE LA ALDEA!'), findsOneWidget);
    await tester.tap(find.text('¡COMENZAR DEFENSA DE LA ALDEA!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify VillageDefenseScreen in landscape
    expect(find.text('MOVER'), findsOneWidget);
  });
}
