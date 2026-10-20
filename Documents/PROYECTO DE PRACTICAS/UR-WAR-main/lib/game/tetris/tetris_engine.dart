import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'tetris_models.dart';

/// Motor del Tetris: solo lógica, sin dibujar nada.
///
/// La pantalla llama a [tick] en cada frame y a los métodos de movimiento
/// cuando el jugador toca una tecla o un botón. Como extiende
/// [ChangeNotifier], la UI se redibuja escuchando los cambios.
class TetrisEngine extends ChangeNotifier {
  TetrisEngine({math.Random? random}) : _random = random ?? math.Random() {
    _board = _emptyBoard();
    _next = _drawFromBag();
  }

  /// Máximo de milisegundos que cuenta un solo frame (evita que la pieza
  /// caiga de golpe si la app se queda en segundo plano).
  static const double _maxFrameMs = 100;

  final math.Random _random;
  final List<TetrominoType> _bag = [];
  /// Poderes ya desbloqueados con puntos de habilidad.
  final Set<PowerType> _unlocked = {};

  /// Milisegundos de recarga que le faltan a cada poder (0 = listo).
  final Map<PowerType, double> _cooldownMs = {
    for (final p in PowerType.values) p: 0,
  };

  late List<List<int>> _board;
  late TetrominoType _next;
  Piece? _current;

  GameStatus _status = GameStatus.ready;
  int _score = 0;
  int _lines = 0;
  double _gravityMs = 0;
  double _freezeMs = 0;
  int _pendingPoints = 0;

  PowerType? _targetPower;
  int _targetRow = 0;
  int _targetCol = 0;

  List<int> _lastClearedRows = const [];
  int _clearEventId = 0;
  int _powerEventId = 0;
  PowerEvent? _lastPowerEvent;

  // ---------------------------------------------------------------- lectura

  /// Tablero de [TetrisConfig.rows] x [TetrisConfig.columns].
  /// 0 = vacío; 1..7 = tipo de pieza + 1. Solo lectura desde la UI.
  List<List<int>> get board => _board;

  Piece? get current => _current;
  TetrominoType get nextType => _next;
  GameStatus get status => _status;
  bool get isPlaying => _status == GameStatus.playing;

  int get score => _score;
  int get lines => _lines;

  /// Nivel actual. Sube cada [TetrisConfig.linesPerLevel] líneas y no tiene
  /// tope: tras el 20 sigue contando (modo infinito).
  int get level => _lines ~/ TetrisConfig.linesPerLevel + 1;

  /// Líneas que faltan para el siguiente nivel.
  int get linesToNextLevel =>
      TetrisConfig.linesPerLevel - (_lines % TetrisConfig.linesPerLevel);

  /// Nivel que se usa para la velocidad (máximo 20).
  int get speedLevel => math.min(level, TetrisConfig.maxSpeedLevel);

  /// Verdadero cuando ya se superó el nivel 20.
  bool get isInfinite => level > TetrisConfig.maxSpeedLevel;

  /// Milisegundos entre caídas en el nivel actual.
  int get fallIntervalMs => TetrisConfig.fallIntervalMs(speedLevel);

  /// Filas que se limpiaron en la última limpieza (para animaciones).
  List<int> get lastClearedRows => _lastClearedRows;

  /// Aumenta en 1 cada vez que se limpian líneas.
  int get clearEventId => _clearEventId;

  /// Puntos de habilidad que aún no se han canjeado.
  int get pendingSkillPoints => _pendingPoints;

  /// Si el poder ya se desbloqueó con un punto de habilidad.
  bool isUnlocked(PowerType type) => _unlocked.contains(type);

  /// Milisegundos que faltan para poder usar el poder de nuevo.
  double cooldownRemainingMs(PowerType type) => _cooldownMs[type] ?? 0;

  /// Desbloqueado y sin recarga pendiente.
  bool isReady(PowerType type) =>
      isUnlocked(type) && cooldownRemainingMs(type) <= 0;

  bool get isFrozen => _freezeMs > 0;
  double get freezeRemainingMs => _freezeMs;

  /// Poder que se está apuntando (solo en estado [GameStatus.targeting]).
  PowerType? get targetPower => _targetPower;
  int get targetRow => _targetRow;
  int get targetCol => _targetCol;

  /// Aumenta cada vez que se usa un poder (para lanzar efectos visuales).
  int get powerEventId => _powerEventId;
  PowerEvent? get lastPowerEvent => _lastPowerEvent;

  /// Posición donde caería la pieza actual (pieza "fantasma").
  Piece? get ghostPiece {
    final p = _current;
    if (p == null) return null;
    var ghost = p;
    while (!_collides(ghost.copyWith(y: ghost.y + 1))) {
      ghost = ghost.copyWith(y: ghost.y + 1);
    }
    return ghost;
  }

  // ---------------------------------------------------------------- control

  /// Empieza una partida nueva.
  void start() {
    _board = _emptyBoard();
    _bag.clear();
    _next = _drawFromBag();
    _current = null;
    _score = 0;
    _lines = 0;
    _gravityMs = 0;
    _freezeMs = 0;
    _pendingPoints = 0;
    _targetPower = null;
    _unlocked.clear();
    for (final p in PowerType.values) {
      _cooldownMs[p] = 0;
    }
    _lastClearedRows = const [];
    _status = GameStatus.playing;
    _spawn();
    notifyListeners();
  }

  void pause() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    notifyListeners();
  }

  /// Avanza el tiempo del juego. Llámalo en cada frame con el tiempo
  /// transcurrido desde el frame anterior.
  void tick(Duration dt) {
    if (_status != GameStatus.playing || _current == null) return;

    final ms = math.min(dt.inMicroseconds / 1000.0, _maxFrameMs);

    // Recarga de los poderes (solo corre mientras se juega).
    for (final p in PowerType.values) {
      final left = _cooldownMs[p] ?? 0;
      if (left > 0) _cooldownMs[p] = math.max(0, left - ms);
    }

    // Congelamiento: la pieza no cae mientras dure.
    if (_freezeMs > 0) {
      _freezeMs = math.max(0, _freezeMs - ms);
      if (_freezeMs == 0) _gravityMs = 0;
      notifyListeners();
      return;
    }

    _gravityMs += ms;
    final interval = fallIntervalMs;
    var changed = false;

    // En niveles altos puede haber más de una caída por frame.
    while (_gravityMs >= interval && _status == GameStatus.playing) {
      _gravityMs -= interval;
      changed = true;
      if (!_moveDown()) _lockCurrent();
    }

    if (changed) notifyListeners();
  }

  void moveLeft() => _tryMove(-1);

  void moveRight() => _tryMove(1);

  void rotateClockwise() => _tryRotate(1);

  void rotateCounterClockwise() => _tryRotate(-1);

  /// Baja la pieza una fila (+1 punto). Si ya no puede bajar, la fija.
  void softDrop() {
    if (!isPlaying || _current == null) return;
    if (_moveDown()) {
      _score += TetrisConfig.softDropPoints;
      _gravityMs = 0;
    } else {
      _lockCurrent();
    }
    notifyListeners();
  }

  /// Deja caer la pieza hasta el fondo y la fija (+2 puntos por fila).
  void hardDrop() {
    if (!isPlaying || _current == null) return;
    var cells = 0;
    while (_moveDown()) {
      cells++;
    }
    _score += cells * TetrisConfig.hardDropPoints;
    _lockCurrent();
    notifyListeners();
  }

  // ----------------------------------------------------------------- poderes

  /// Canjea un punto de habilidad para desbloquear un poder (ya no se pierde:
  /// después solo hay que esperar su recarga). No sirve elegir uno ya
  /// desbloqueado.
  bool choosePower(PowerType type) {
    if (_status != GameStatus.choosingPower || _pendingPoints <= 0) {
      return false;
    }
    if (_unlocked.contains(type)) return false;
    _unlocked.add(type);
    _pendingPoints--;
    if (_pendingPoints == 0) {
      _status = GameStatus.playing;
      _gravityMs = 0;
    }
    notifyListeners();
    return true;
  }

  /// Usa un poder. Congelamiento y Transformación actúan al instante;
  /// Rayo y Bomba pasan a modo "elegir objetivo" (el juego queda en pausa).
  /// La recarga de 20 s empieza al activarlo. Devuelve false si no se pudo
  /// usar (no inicia la recarga).
  bool usePower(PowerType type) {
    if (_status != GameStatus.playing || _current == null) return false;
    if (!isReady(type)) return false;

    if (type == PowerType.lightning || type == PowerType.bomb) {
      _beginTargeting(type);
      notifyListeners();
      return true;
    }

    if (type == PowerType.freeze) {
      if (_freezeMs > 0) return false;
      _freezeMs = TetrisConfig.freezeDurationMs.toDouble();
    } else {
      if (!_transformToI()) return false;
    }

    _startCooldown(type);
    final (row, col) = _pieceCenter();
    _emit(type, row, col);
    notifyListeners();
    return true;
  }

  /// Mueve el cursor del objetivo con las flechas.
  void moveTarget(int dRow, int dCol) {
    if (_status != GameStatus.targeting) return;
    _targetRow = math.max(0, math.min(TetrisConfig.rows - 1, _targetRow + dRow));
    _targetCol =
        math.max(0, math.min(TetrisConfig.columns - 1, _targetCol + dCol));
    notifyListeners();
  }

  /// Coloca el cursor en una celda concreta (toque en pantalla).
  void setTarget(int row, int col) {
    if (_status != GameStatus.targeting) return;
    _targetRow = math.max(0, math.min(TetrisConfig.rows - 1, row));
    _targetCol = math.max(0, math.min(TetrisConfig.columns - 1, col));
    notifyListeners();
  }

  /// Confirma el objetivo. Si ahí no hay bloques devuelve false, no inicia la
  /// recarga y sigue en modo elegir.
  bool confirmTarget() {
    final power = _targetPower;
    if (_status != GameStatus.targeting || power == null) return false;

    final row = _targetRow;
    final col = _targetCol;
    final applied = power == PowerType.lightning
        ? _applyLightning(row)
        : _applyBomb(row, col);
    if (!applied) return false;

    _startCooldown(power);
    _targetPower = null;
    _status = GameStatus.playing;
    _emit(power, row, power == PowerType.lightning
        ? TetrisConfig.columns ~/ 2
        : col);

    _fixCurrentAfterBoardChange();
    if (power == PowerType.bomb && _status == GameStatus.playing) {
      _clearLines(); // la gravedad pudo completar filas
    }
    notifyListeners();
    return true;
  }

  /// Cancela la selección: vuelve al juego sin iniciar la recarga.
  void cancelTarget() {
    if (_status != GameStatus.targeting) return;
    _targetPower = null;
    _status = GameStatus.playing;
    notifyListeners();
  }

  /// ATAJO DE PRUEBA (tecla L): sube [levels] niveles de golpe y da los
  /// puntos de habilidad de los niveles que se saltan. Bórralo al terminar.
  void debugLevelUp(int levels) {
    if (_status != GameStatus.playing) return;
    final levelBefore = level;
    _lines = (levelBefore - 1 + levels) * TetrisConfig.linesPerLevel;
    for (var l = levelBefore + 1; l <= level; l++) {
      _grantSkillPointFor(l);
    }
    if (_pendingPoints > 0) _status = GameStatus.choosingPower;
    notifyListeners();
  }

  // ----------------------------------------------------------- internos

  List<List<int>> _emptyBoard() => List.generate(
        TetrisConfig.rows,
        (_) => List.filled(TetrisConfig.columns, 0),
      );

  /// Bolsa de 7: cada ronda salen las 7 piezas en orden aleatorio.
  TetrominoType _drawFromBag() {
    if (_bag.isEmpty) {
      _bag
        ..addAll(TetrominoType.values)
        ..shuffle(_random);
    }
    return _bag.removeLast();
  }

  bool _collides(Piece p) {
    for (final (c, r) in p.cells) {
      if (c < 0 || c >= TetrisConfig.columns || r >= TetrisConfig.rows) {
        return true;
      }
      if (r >= 0 && _board[r][c] != 0) return true;
    }
    return false;
  }

  bool _moveDown() {
    final p = _current;
    if (p == null) return false;
    final moved = p.copyWith(y: p.y + 1);
    if (_collides(moved)) return false;
    _current = moved;
    return true;
  }

  void _tryMove(int dx) {
    final p = _current;
    if (!isPlaying || p == null) return;
    final moved = p.copyWith(x: p.x + dx);
    if (_collides(moved)) return;
    _current = moved;
    notifyListeners();
  }

  void _tryRotate(int direction) {
    final p = _current;
    if (!isPlaying || p == null) return;
    if (p.type == TetrominoType.o) return; // la O no cambia al rotar

    final newRotation = (p.rotation + direction + 4) % 4;

    // "Wall kick" sencillo: si no cabe, prueba desplazarla un poco.
    for (final dy in const [0, -1]) {
      for (final dx in const [0, -1, 1, -2, 2]) {
        final candidate = p.copyWith(
          rotation: newRotation,
          x: p.x + dx,
          y: p.y + dy,
        );
        if (!_collides(candidate)) {
          _current = candidate;
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Fija la pieza actual en el tablero, limpia líneas y saca la siguiente.
  void _lockCurrent() {
    final p = _current;
    if (p == null) return;

    var overflow = false;
    for (final (c, r) in p.cells) {
      if (r < 0) {
        overflow = true; // quedó fuera por arriba
        continue;
      }
      _board[r][c] = p.type.index + 1;
    }

    _current = null;
    _gravityMs = 0;
    _freezeMs = 0; // el congelamiento solo afecta a la pieza actual

    if (overflow) {
      _status = GameStatus.gameOver;
      return;
    }

    _clearLines();
    _spawn();
  }

  void _clearLines() {
    final full = <int>[];
    for (var r = 0; r < TetrisConfig.rows; r++) {
      if (_board[r].every((v) => v != 0)) full.add(r);
    }
    _lastClearedRows = full;
    if (full.isEmpty) return;

    final levelBefore = level;

    // Las filas llenas están en orden ascendente, así que los índices de las
    // siguientes siguen siendo válidos tras quitar una e insertar otra arriba.
    for (final r in full) {
      _board.removeAt(r);
      _board.insert(0, List.filled(TetrisConfig.columns, 0));
    }

    _lines += full.length;
    final index = math.min(full.length, TetrisConfig.lineScores.length - 1);
    _score += TetrisConfig.lineScores[index] * levelBefore;
    _clearEventId++;

    // Puntos de habilidad al llegar a los niveles 5, 10, 15 y 20.
    final levelAfter = level;
    for (var l = levelBefore + 1; l <= levelAfter; l++) {
      _grantSkillPointFor(l);
    }
    if (_pendingPoints > 0 && _status == GameStatus.playing) {
      _status = GameStatus.choosingPower;
    }
  }

  void _spawn() {
    _spawnType(_next);
    _next = _drawFromBag();
  }

  void _spawnType(TetrominoType type) {
    final p = Piece.spawn(type);
    _current = p;
    _gravityMs = 0;
    if (_collides(p)) _status = GameStatus.gameOver;
  }

  // ---- poderes (internos)

  void _startCooldown(PowerType type) {
    _cooldownMs[type] = TetrisConfig.powerCooldownMs.toDouble();
  }

  /// Da un punto de habilidad si el nivel [l] lo merece y aún queda algún
  /// poder por desbloquear.
  void _grantSkillPointFor(int l) {
    if (!TetrisConfig.skillPointLevels.contains(l)) return;
    final locked = PowerType.values.length - _unlocked.length;
    if (_pendingPoints < locked) _pendingPoints++;
  }

  void _emit(PowerType type, int row, int col) {
    _lastPowerEvent = PowerEvent(type: type, row: row, col: col);
    _powerEventId++;
  }

  /// Centro de la pieza actual como (fila, columna).
  (int, int) _pieceCenter() {
    final p = _current;
    if (p == null) return (TetrisConfig.rows ~/ 2, TetrisConfig.columns ~/ 2);
    final cells = p.cells;
    var sumR = 0;
    var sumC = 0;
    for (final (c, r) in cells) {
      sumR += r;
      sumC += c;
    }
    return (sumR ~/ cells.length, sumC ~/ cells.length);
  }

  void _beginTargeting(PowerType type) {
    _targetPower = type;
    _targetCol = TetrisConfig.columns ~/ 2;
    // Rayo: fila inferior. Bomba: centro del tablero.
    _targetRow = type == PowerType.lightning
        ? TetrisConfig.rows - 1
        : TetrisConfig.rows ~/ 2;
    _status = GameStatus.targeting;
  }

  /// Convierte la pieza actual en una I. Si no cabe donde está, prueba
  /// desplazarla y, por último, el punto de aparición.
  bool _transformToI() {
    final p = _current;
    if (p == null || p.type == TetrominoType.i) return false;

    final maxX = TetrisConfig.columns - 4;
    final baseX = math.max(0, math.min(p.x, maxX));
    for (final dx in const [0, -1, 1, -2, 2]) {
      final x = math.max(0, math.min(baseX + dx, maxX));
      // La fila de bloques de la I está en la 2.ª fila de su matriz.
      final candidate = Piece(type: TetrominoType.i, x: x, y: p.y - 1);
      if (!_collides(candidate)) {
        _current = candidate;
        return true;
      }
    }
    final spawn = Piece.spawn(TetrominoType.i);
    if (!_collides(spawn)) {
      _current = spawn;
      return true;
    }
    return false;
  }

  bool _applyLightning(int row) {
    if (_board[row].every((v) => v == 0)) return false;
    _board.removeAt(row);
    _board.insert(0, List.filled(TetrisConfig.columns, 0));
    return true;
  }

  bool _applyBomb(int row, int col) {
    final r0 = math.max(0, row - 1);
    final r1 = math.min(TetrisConfig.rows - 1, row + 1);
    final c0 = math.max(0, col - 1);
    final c1 = math.min(TetrisConfig.columns - 1, col + 1);

    var any = false;
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        if (_board[r][c] != 0) {
          any = true;
          _board[r][c] = 0;
        }
      }
    }
    if (!any) return false;

    for (var c = c0; c <= c1; c++) {
      _applyColumnGravity(c);
    }
    return true;
  }

  /// Los bloques de una columna caen hasta apoyarse abajo.
  void _applyColumnGravity(int c) {
    final values = <int>[];
    for (var r = TetrisConfig.rows - 1; r >= 0; r--) {
      if (_board[r][c] != 0) values.add(_board[r][c]);
    }
    for (var r = TetrisConfig.rows - 1; r >= 0; r--) {
      final i = TetrisConfig.rows - 1 - r;
      _board[r][c] = i < values.length ? values[i] : 0;
    }
  }

  /// Tras cambiar el tablero, si la pieza actual quedó encima de bloques la
  /// subimos; si no hay forma, es game over.
  void _fixCurrentAfterBoardChange() {
    final start = _current;
    if (start == null) return;
    var p = start; // tipo Piece (no nulo)
    var guard = 0;
    while (_collides(p) && guard < 4) {
      p = p.copyWith(y: p.y - 1);
      guard++;
    }
    if (_collides(p)) {
      _status = GameStatus.gameOver;
    } else {
      _current = p;
    }
  }

  // ------------------------------------------------------ solo para tests

  @visibleForTesting
  void spawnForTest(TetrominoType type) {
    _spawnType(type);
    notifyListeners();
  }

  @visibleForTesting
  void setLinesForTest(int lines) {
    _lines = lines;
    notifyListeners();
  }

  @visibleForTesting
  void unlockPowerForTest(PowerType type) {
    _unlocked.add(type);
    notifyListeners();
  }
}