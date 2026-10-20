import 'package:flutter_test/flutter_test.dart';
import 'package:ur_war/providers/game_state.dart';

void main() {
  group('available actions', () {
    late GameState game;

    setUp(() {
      game = GameState();
    });

    test('highlights only adjacent unoccupied movement cells', () {
      expect(game.canMoveTo(1, 2), isFalse);

      game.onCellTapped(1, 1);

      expect(game.canMoveTo(1, 2), isTrue);
      expect(game.canMoveTo(2, 2), isFalse);
      expect(game.canMoveTo(1, 1), isFalse);
    });

    test('highlights enemies only when in attack range', () {
      game.onCellTapped(1, 1);

      expect(game.canAttackAt(6, 6), isFalse);
      game.robots.last.x = 2;
      game.robots.last.y = 1;
      expect(game.canAttackAt(2, 1), isTrue);

      game.selectedRobot!.actionPoints = 0;
      expect(game.canAttackAt(2, 1), isFalse);
      expect(game.canMoveTo(1, 2), isFalse);
    });
  });
}
