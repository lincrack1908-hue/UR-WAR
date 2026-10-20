import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ur_war/game/tetris/tetris_engine.dart';
import 'package:ur_war/game/tetris/tetris_models.dart';

TetrisEngine _newEngine() => TetrisEngine(random: Random(42));

int _filledCells(TetrisEngine e) =>
    e.board.expand((row) => row).where((v) => v != 0).length;

/// Hace avanzar el juego [ms] milisegundos en pasos de 100 ms.
void _advance(TetrisEngine e, int ms) {
  for (var t = 0; t < ms; t += 100) {
    e.tick(const Duration(milliseconds: 100));
  }
}

void main() {
  group('TetrisConfig', () {
    test('la velocidad baja de forma pareja de 800 ms a 100 ms', () {
      expect(TetrisConfig.fallIntervalMs(1), 800);
      expect(TetrisConfig.fallIntervalMs(20), 100);
      for (var level = 2; level <= 20; level++) {
        expect(
          TetrisConfig.fallIntervalMs(level),
          lessThan(TetrisConfig.fallIntervalMs(level - 1)),
        );
      }
    });

    test('fuera de rango usa el nivel más cercano', () {
      expect(TetrisConfig.fallIntervalMs(0), 800);
      expect(TetrisConfig.fallIntervalMs(99), 100);
    });
  });

  group('TetrisEngine', () {
    test('empieza listo, con el tablero vacío', () {
      final e = _newEngine();
      expect(e.status, GameStatus.ready);
      expect(e.board.length, TetrisConfig.rows);
      expect(e.board.first.length, TetrisConfig.columns);
      expect(_filledCells(e), 0);
    });

    test('start() deja una pieza en juego y la siguiente lista', () {
      final e = _newEngine()..start();
      expect(e.status, GameStatus.playing);
      expect(e.current, isNotNull);
      expect(e.score, 0);
      expect(e.level, 1);
    });

    test('la pieza no puede salirse por los lados', () {
      final e = _newEngine()..start();
      for (var i = 0; i < 20; i++) {
        e.moveLeft();
      }
      expect(e.current!.cells.every((cell) => cell.$1 >= 0), isTrue);
      for (var i = 0; i < 30; i++) {
        e.moveRight();
      }
      expect(
        e.current!.cells.every((cell) => cell.$1 < TetrisConfig.columns),
        isTrue,
      );
    });

    test('rotar junto a la pared mantiene la pieza dentro del tablero', () {
      final e = _newEngine()..start();
      e.spawnForTest(TetrominoType.t);
      for (var i = 0; i < 10; i++) {
        e.moveLeft();
      }
      for (var i = 0; i < 3; i++) {
        e.rotateClockwise();
        expect(
          e.current!.cells.every(
            (cell) => cell.$1 >= 0 && cell.$1 < TetrisConfig.columns,
          ),
          isTrue,
        );
      }
    });

    test('hardDrop fija la pieza (4 bloques) y aparece otra', () {
      final e = _newEngine()..start();
      e.hardDrop();
      expect(_filledCells(e), 4);
      expect(e.status, GameStatus.playing);
      expect(e.current, isNotNull);
      expect(e.score, 0); // bajar la pieza no da puntos
    });

    test('la gravedad baja la pieza una fila al cumplirse el intervalo', () {
      final e = _newEngine()..start();
      final before = e.current!.y;
      _advance(e, 800); // intervalo del nivel 1
      expect(e.current!.y, before + 1);
    });

    test('en pausa el tiempo no avanza', () {
      final e = _newEngine()..start();
      final before = e.current!.y;
      e.pause();
      _advance(e, 2000);
      expect(e.status, GameStatus.paused);
      expect(e.current!.y, before);
      e.resume();
      expect(e.status, GameStatus.playing);
    });

    test('limpiar 2 líneas suma 300 puntos x nivel', () {
      final e = _newEngine()..start();
      for (var c = 2; c < TetrisConfig.columns; c++) {
        e.board[18][c] = 1;
        e.board[19][c] = 1;
      }
      e.spawnForTest(TetrominoType.o);
      while (e.current!.x > 0) {
        e.moveLeft();
      }
      e.hardDrop(); // bajar no da puntos; 2 líneas = 300

      expect(e.lines, 2);
      expect(e.score, 300);
      expect(e.lastClearedRows, [18, 19]);
      expect(_filledCells(e), 0);
    });

    test('el nivel sube cada linesPerLevel líneas y tras el 20 es infinito', () {
      final e = _newEngine()..start();
      const l = TetrisConfig.linesPerLevel;

      e.setLinesForTest(5 * l - 1);
      expect(e.level, 5);
      e.setLinesForTest(5 * l);
      expect(e.level, 6);

      e.setLinesForTest(19 * l);
      expect(e.level, 20);
      expect(e.isInfinite, isFalse);

      e.setLinesForTest(20 * l);
      expect(e.level, 21);
      expect(e.isInfinite, isTrue);
      expect(e.speedLevel, 20);
      expect(e.fallIntervalMs, 100);
    });

    test('game over cuando no hay espacio para la pieza nueva', () {
      final e = _newEngine()..start();
      for (var c = 0; c < TetrisConfig.columns; c++) {
        e.board[0][c] = 1;
        e.board[1][c] = 1;
      }
      e.spawnForTest(TetrominoType.t);
      expect(e.status, GameStatus.gameOver);
    });
  });

  group('Puntos de habilidad y poderes', () {
    /// Deja el motor a una línea de llegar al nivel [target] y limpia esa línea.
    void reachLevel(TetrisEngine e, int target) {
      e.setLinesForTest((target - 1) * TetrisConfig.linesPerLevel - 1);
      for (var c = 1; c < TetrisConfig.columns; c++) {
        e.board[19][c] = 1;
      }
      e.spawnForTest(TetrominoType.i);
      e.rotateClockwise(); // I vertical: ocupa la columna x + 2
      for (var i = 0; i < 10; i++) {
        e.moveLeft();
      }
      e.hardDrop(); // rellena la columna 0 y completa la fila 19
    }

    test('al llegar al nivel 5 se pausa y da 1 punto de habilidad', () {
      final e = _newEngine()..start();
      reachLevel(e, 5);

      expect(e.level, 5);
      expect(e.status, GameStatus.choosingPower);
      expect(e.pendingSkillPoints, 1);
    });

    test('en niveles sin recompensa no aparece la pantalla de poderes', () {
      final e = _newEngine()..start();
      reachLevel(e, 4);

      expect(e.level, 4);
      expect(e.status, GameStatus.playing);
      expect(e.pendingSkillPoints, 0);
    });

    test('canjear el punto desbloquea el poder y el juego continúa', () {
      final e = _newEngine()..start();
      reachLevel(e, 5);

      expect(e.isUnlocked(PowerType.bomb), isFalse);
      expect(e.choosePower(PowerType.bomb), isTrue);
      expect(e.isUnlocked(PowerType.bomb), isTrue);
      expect(e.isReady(PowerType.bomb), isTrue);
      expect(e.pendingSkillPoints, 0);
      expect(e.status, GameStatus.playing);
      // Ya no hay punto para canjear
      expect(e.choosePower(PowerType.freeze), isFalse);
    });

    test('no se puede elegir un poder que ya está desbloqueado', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.bomb);
      reachLevel(e, 5);

      expect(e.status, GameStatus.choosingPower);
      expect(e.choosePower(PowerType.bomb), isFalse);
      expect(e.status, GameStatus.choosingPower);
      expect(e.choosePower(PowerType.freeze), isTrue);
    });

    test('un poder bloqueado no se puede usar', () {
      final e = _newEngine()..start();
      for (final p in PowerType.values) {
        expect(e.usePower(p), isFalse);
      }
      expect(e.status, GameStatus.playing);
    });

    test('Rayo: elimina una fila incompleta y baja lo de arriba', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.lightning);
      for (var c = 0; c < 5; c++) {
        e.board[19][c] = 1;
      }
      e.board[18][0] = 2;

      expect(e.usePower(PowerType.lightning), isTrue);
      expect(e.status, GameStatus.targeting);
      expect(e.targetRow, TetrisConfig.rows - 1); // por defecto, fila inferior

      expect(e.confirmTarget(), isTrue);
      expect(e.status, GameStatus.playing);
      expect(e.board[19][0], 2); // lo de arriba bajó una fila
      expect(e.board[19][4], 0);
    });

    test('tras usar un poder hay 20 s de recarga y luego vuelve a estar listo', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.lightning);
      e.board[19][0] = 1;

      e.usePower(PowerType.lightning);
      e.confirmTarget();

      expect(e.isReady(PowerType.lightning), isFalse);
      expect(e.cooldownRemainingMs(PowerType.lightning), 20000);

      // Mientras recarga no se puede usar
      expect(e.usePower(PowerType.lightning), isFalse);

      // La pausa congela la recarga
      e.pause();
      _advance(e, 5000);
      expect(e.cooldownRemainingMs(PowerType.lightning), 20000);
      e.resume();

      // Evita que la pieza llegue arriba del tablero mientras pasa el tiempo
      for (var i = 0; i < 25 && e.status == GameStatus.playing; i++) {
        _advance(e, 1000);
        // Mantiene el tablero libre para que la partida no termine
        for (final row in e.board) {
          row.fillRange(0, row.length, 0);
        }
      }
      expect(e.status, GameStatus.playing);
      expect(e.cooldownRemainingMs(PowerType.lightning), 0);
      expect(e.isReady(PowerType.lightning), isTrue);
    });

    test('Bomba: borra 3x3, los bloques de arriba caen y cancelar no gasta', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.bomb);
      e.board[10][5] = 1;
      e.board[5][5] = 3;

      expect(e.usePower(PowerType.bomb), isTrue);
      expect(e.targetRow, TetrisConfig.rows ~/ 2);
      expect(e.targetCol, TetrisConfig.columns ~/ 2);

      // Cancelar devuelve al juego sin iniciar la recarga
      e.cancelTarget();
      expect(e.status, GameStatus.playing);
      expect(e.isReady(PowerType.bomb), isTrue);

      e.usePower(PowerType.bomb);
      expect(e.confirmTarget(), isTrue);
      expect(e.board[10][5], 0);
      expect(e.board[5][5], 0);
      expect(e.board[19][5], 3); // cayó hasta el fondo
      expect(e.isReady(PowerType.bomb), isFalse);
    });

    test('Bomba o Rayo en una zona vacía no se confirman ni recargan', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.bomb);
      e.unlockPowerForTest(PowerType.lightning);

      e.usePower(PowerType.bomb);
      expect(e.confirmTarget(), isFalse);
      expect(e.status, GameStatus.targeting);
      e.cancelTarget();

      e.usePower(PowerType.lightning);
      expect(e.confirmTarget(), isFalse);
      e.cancelTarget();

      expect(e.isReady(PowerType.bomb), isTrue);
      expect(e.isReady(PowerType.lightning), isTrue);
    });

    test('Congelamiento: la pieza no cae durante 6 s y luego se reanuda', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.freeze);
      final y = e.current!.y;

      expect(e.usePower(PowerType.freeze), isTrue);
      expect(e.isFrozen, isTrue);
      expect(e.freezeRemainingMs, 6000);

      _advance(e, 5000);
      expect(e.current!.y, y);
      expect(e.isFrozen, isTrue);

      _advance(e, 1000); // se cumplen los 6 s
      expect(e.isFrozen, isFalse);

      _advance(e, 800); // vuelve a caer
      expect(e.current!.y, greaterThan(y));
    });

    test('Congelamiento termina al fijar la pieza con caída instantánea', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.freeze);
      e.usePower(PowerType.freeze);
      e.hardDrop();
      expect(e.isFrozen, isFalse);
    });

    test('Transformación Divina convierte la pieza actual en I', () {
      final e = _newEngine()..start();
      e.unlockPowerForTest(PowerType.divine);
      e.spawnForTest(TetrominoType.t);

      expect(e.usePower(PowerType.divine), isTrue);
      expect(e.current!.type, TetrominoType.i);
      expect(e.isReady(PowerType.divine), isFalse);
      expect(
        e.current!.cells.every(
          (cell) => cell.$1 >= 0 && cell.$1 < TetrisConfig.columns,
        ),
        isTrue,
      );
    });
  });
}