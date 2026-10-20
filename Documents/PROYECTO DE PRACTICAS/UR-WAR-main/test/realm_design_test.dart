import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ur_war/core/theme.dart';
import 'package:ur_war/core/save_system.dart';
import 'package:ur_war/game/logic/game_engine.dart';
import 'package:ur_war/game/models/game_map.dart';
import 'package:ur_war/game/models/player_class.dart';
import 'package:ur_war/game/widgets/village_shop_dialog.dart';
import 'package:ur_war/providers/game_state.dart';
import 'package:ur_war/screens/character_select_screen.dart';
import 'package:ur_war/screens/game_screen.dart';
import 'package:ur_war/screens/settings_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SaveSystem.initialize();
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Realm screens remain usable at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget child) => MaterialApp(
        key: ValueKey(child.runtimeType),
        theme: AppTheme.darkTheme,
        home: child,
      );
      await tester.pumpWidget(app(const CharacterSelectScreen()));
      await tester.pumpAndSettle();
      for (final hero in ['Cazadora', 'Mago', 'Guardiana', 'Caballero']) {
        await tester.tap(find.text(hero));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('CONTINUAR: ELEGIR MAPA'));
      await tester.pumpAndSettle();
      expect(find.text('ELIGE TU TERRITORIO'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'CONTROLES'));
      await tester.pumpAndSettle();
      expect(find.text('EN EL CAMPO DE BATALLA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(OutlinedButton, 'PERFIL'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final game = GameState()
        ..isGameOver = true
        ..winnerMessage = '¡Victoria! El territorio está a salvo.';
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: app(const GameScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('REINICIAR'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('REINICIAR'));
      await tester.pumpAndSettle();
      expect(game.isGameOver, isFalse);
      final engine = GameEngine(
        map: GameMapModel.availableMaps.first,
        playerClass: PlayerClass.availableClasses.first,
      );
      await tester.pumpWidget(
        app(Scaffold(body: VillageShopDialog(engine: engine))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONSTRUIR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      engine.dispose();
      game.dispose();
    });
  }
}
