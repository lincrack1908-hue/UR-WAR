import 'dart:math' as math;

/// Configuración general del Tetris con poderes.
/// Todo lo que quieras balancear (velocidad, puntos, tamaño) está aquí.
class TetrisConfig {
  TetrisConfig._();

  static const int columns = 10;
  static const int rows = 20;

  /// Líneas necesarias para completar un nivel (súbelo si quieres que
  /// avance más lento, bájalo si lo quieres más rápido).
  static const int linesPerLevel = 4;

  /// Al llegar a estos niveles el juego se pausa y das 1 punto de habilidad.
  static const List<int> skillPointLevels = [5, 10, 15, 20];

  /// Duración del Congelamiento Temporal.
  static const int freezeDurationMs = 6000;

  /// Tiempo de recarga de cada poder tras usarlo (20 s).
  static const int powerCooldownMs = 20000;

  /// Nivel de velocidad máximo. El nivel 20 es el más rápido.
  static const int maxSpeedLevel = 20;

  /// Milisegundos entre caídas en el nivel 1 (como el Tetris clásico).
  static const int slowestIntervalMs = 800;

  /// Milisegundos entre caídas en el nivel 20 (rápido pero jugable).
  static const int fastestIntervalMs = 100;

  /// Puntos base por limpiar 0, 1, 2, 3 o 4 líneas (se multiplican por el nivel).
  static const List<int> lineScores = [0, 100, 300, 500, 800];

  /// Puntos por bajar la pieza. En 0: solo se puntúa al limpiar líneas.
  static const int softDropPoints = 0;
  static const int hardDropPoints = 0;

  /// Tabla de intervalos por nivel (índice 0 = nivel 1).
  /// Baja de forma pareja (lineal) de 800 ms a 100 ms, como en el Tetris
  /// clásico: cada nivel es un poco más rápido que el anterior.
  static final List<int> fallIntervalsMs =
      List<int>.generate(maxSpeedLevel, (i) {
    final t = i / (maxSpeedLevel - 1);
    return (slowestIntervalMs + (fastestIntervalMs - slowestIntervalMs) * t)
        .round();
  });

  /// Intervalo de caída (ms) para un nivel de velocidad (1 a 20).
  static int fallIntervalMs(int speedLevel) {
    final level = math.max(1, math.min(speedLevel, maxSpeedLevel));
    return fallIntervalsMs[level - 1];
  }
}

/// Estado de la partida.
/// - choosingPower: pantalla para canjear un punto de habilidad.
/// - targeting: el jugador elige la fila o zona de un poder.
enum GameStatus { ready, playing, paused, choosingPower, targeting, gameOver }

/// Aviso de que se usó un poder (para los efectos visuales).
class PowerEvent {
  const PowerEvent({required this.type, required this.row, required this.col});

  final PowerType type;
  final int row;
  final int col;
}

/// Los 4 poderes del juego (se implementan en el paso 3).
enum PowerType {
  lightning(
    '⚡',
    'Rayo Desintegrador',
    'Elimina una fila sin necesidad de completarla.',
  ),
  bomb(
    '💣',
    'Bomba Sísmica',
    'Explota un área de bloques en la zona elegida.',
  ),
  freeze(
    '🔄',
    'Congelamiento Temporal',
    'Detiene la caída de la pieza actual unos segundos.',
  ),
  divine(
    '✨',
    'Transformación Divina',
    'Convierte la pieza actual en una Barra Recta (I).',
  );

  const PowerType(this.icon, this.displayName, this.description);

  final String icon;
  final String displayName;
  final String description;
}

/// Las 7 piezas clásicas.
enum TetrominoType { i, o, t, s, z, j, l }

/// Formas de las piezas y sus 4 rotaciones.
class TetrisShapes {
  TetrisShapes._();

  static const Map<TetrominoType, List<List<int>>> _base = {
    TetrominoType.i: [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    TetrominoType.o: [
      [1, 1],
      [1, 1],
    ],
    TetrominoType.t: [
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.s: [
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0],
    ],
    TetrominoType.z: [
      [1, 1, 0],
      [0, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.j: [
      [1, 0, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    TetrominoType.l: [
      [0, 0, 1],
      [1, 1, 1],
      [0, 0, 0],
    ],
  };

  static final Map<TetrominoType, List<List<List<int>>>> _rotations = {
    for (final type in TetrominoType.values) type: _buildRotations(_base[type]!),
  };

  /// Matriz de la pieza [type] en la rotación [rotation] (0 a 3).
  static List<List<int>> matrix(TetrominoType type, int rotation) =>
      _rotations[type]![rotation % 4];

  static List<List<List<int>>> _buildRotations(List<List<int>> base) {
    final result = <List<List<int>>>[base];
    for (var i = 1; i < 4; i++) {
      result.add(_rotateClockwise(result.last));
    }
    return result;
  }

  static List<List<int>> _rotateClockwise(List<List<int>> m) {
    final n = m.length;
    return List.generate(
      n,
      (r) => List.generate(n, (c) => m[n - 1 - c][r]),
    );
  }
}

/// Una pieza en el tablero. Es inmutable: para moverla se crea una copia.
class Piece {
  const Piece({
    required this.type,
    this.rotation = 0,
    required this.x,
    required this.y,
  });

  /// Pieza recién aparecida, centrada en la parte superior del tablero.
  factory Piece.spawn(TetrominoType type) {
    final size = TetrisShapes.matrix(type, 0).length;
    return Piece(
      type: type,
      x: (TetrisConfig.columns - size) ~/ 2,
      // La pieza I tiene su fila de bloques en la 2.ª fila de la matriz.
      y: type == TetrominoType.i ? -1 : 0,
    );
  }

  final TetrominoType type;
  final int rotation;

  /// Columna de la esquina superior izquierda de la matriz.
  final int x;

  /// Fila de la esquina superior izquierda de la matriz (puede ser -1 al aparecer).
  final int y;

  List<List<int>> get matrix => TetrisShapes.matrix(type, rotation);

  /// Celdas ocupadas como (columna, fila) en coordenadas del tablero.
  List<(int, int)> get cells {
    final m = matrix;
    final result = <(int, int)>[];
    for (var r = 0; r < m.length; r++) {
      for (var c = 0; c < m[r].length; c++) {
        if (m[r][c] == 1) result.add((x + c, y + r));
      }
    }
    return result;
  }

  Piece copyWith({int? rotation, int? x, int? y}) => Piece(
        type: type,
        rotation: rotation ?? this.rotation,
        x: x ?? this.x,
        y: y ?? this.y,
      );
}