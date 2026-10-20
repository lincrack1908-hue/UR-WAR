import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tetris_engine.dart';
import 'tetris_models.dart';

/// Colores de cada pieza.
class TetrisColors {
  TetrisColors._();

  static const Map<TetrominoType, Color> pieces = {
    TetrominoType.i: Color(0xFF22D3EE),
    TetrominoType.o: Color(0xFFFACC15),
    TetrominoType.t: Color(0xFFA855F7),
    TetrominoType.s: Color(0xFF4ADE80),
    TetrominoType.z: Color(0xFFE63946),
    TetrominoType.j: Color(0xFF3B82F6),
    TetrominoType.l: Color(0xFFFB923C),
  };

  static Color of(TetrominoType type) => pieces[type]!;
}

/// Medidas del tablero dentro de un área. Las usan el painter y la pantalla
/// (para convertir un toque en una celda).
class TetrisGeometry {
  TetrisGeometry._(this.cell, this.origin);

  factory TetrisGeometry.of(Size size) {
    final cell = math.min(
      size.width / TetrisConfig.columns,
      size.height / TetrisConfig.rows,
    );
    final w = cell * TetrisConfig.columns;
    final h = cell * TetrisConfig.rows;
    return TetrisGeometry._(
      cell,
      Offset((size.width - w) / 2, (size.height - h) / 2),
    );
  }

  final double cell;
  final Offset origin;

  double get width => cell * TetrisConfig.columns;
  double get height => cell * TetrisConfig.rows;
  Rect get boardRect => origin & Size(width, height);

  Rect cellRect(int col, int row) => Rect.fromLTWH(
        origin.dx + col * cell,
        origin.dy + row * cell,
        cell,
        cell,
      );

  /// Celda (fila, columna) bajo el punto [p], limitada al tablero.
  (int, int) cellAt(Offset p) {
    final col = ((p.dx - origin.dx) / cell).floor();
    final row = ((p.dy - origin.dy) / cell).floor();
    return (
      math.max(0, math.min(TetrisConfig.rows - 1, row)),
      math.max(0, math.min(TetrisConfig.columns - 1, col)),
    );
  }
}

/// Dibuja un bloque con esquinas redondeadas y un pequeño brillo.
void paintTetrisCell(
  Canvas canvas,
  Rect rect,
  Color color, {
  double opacity = 1,
}) {
  final r = rect.deflate(rect.width * 0.05);
  final radius = Radius.circular(r.width * 0.18);

  canvas.drawRRect(
    RRect.fromRectAndRadius(r, radius),
    Paint()..color = color.withValues(alpha: opacity),
  );

  final shine = Rect.fromLTWH(
    r.left + r.width * 0.12,
    r.top + r.height * 0.10,
    r.width * 0.76,
    r.height * 0.20,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(shine, Radius.circular(r.width * 0.10)),
    Paint()..color = Colors.white.withValues(alpha: 0.28 * opacity),
  );
}

/// Dibuja el tablero, las piezas fijadas, la pieza fantasma, la pieza actual
/// y el cursor de los poderes. Se redibuja cuando el motor avisa de un cambio.
class TetrisBoardPainter extends CustomPainter {
  TetrisBoardPainter(this.engine) : super(repaint: engine);

  final TetrisEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final g = TetrisGeometry.of(size);
    final cell = g.cell;

    // Fondo
    canvas.drawRect(g.boardRect, Paint()..color = const Color(0xFF0B1220));

    // Cuadrícula
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var c = 1; c < TetrisConfig.columns; c++) {
      final x = g.origin.dx + c * cell;
      canvas.drawLine(
        Offset(x, g.origin.dy),
        Offset(x, g.origin.dy + g.height),
        gridPaint,
      );
    }
    for (var r = 1; r < TetrisConfig.rows; r++) {
      final y = g.origin.dy + r * cell;
      canvas.drawLine(
        Offset(g.origin.dx, y),
        Offset(g.origin.dx + g.width, y),
        gridPaint,
      );
    }

    // Bloques ya fijados
    final board = engine.board;
    for (var r = 0; r < TetrisConfig.rows; r++) {
      for (var c = 0; c < TetrisConfig.columns; c++) {
        final v = board[r][c];
        if (v == 0) continue;
        final type = TetrominoType.values[(v - 1) % TetrominoType.values.length];
        paintTetrisCell(canvas, g.cellRect(c, r), TetrisColors.of(type));
      }
    }

    // Pieza fantasma (dónde caería)
    final ghost = engine.ghostPiece;
    final current = engine.current;
    if (ghost != null && current != null && ghost.y != current.y) {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = TetrisColors.of(ghost.type).withValues(alpha: 0.55);
      for (final (c, r) in ghost.cells) {
        if (r < 0) continue;
        final rect = g.cellRect(c, r).deflate(cell * 0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.15)),
          outline,
        );
      }
    }

    // Pieza actual
    if (current != null) {
      for (final (c, r) in current.cells) {
        if (r < 0) continue;
        paintTetrisCell(canvas, g.cellRect(c, r), TetrisColors.of(current.type));
      }
    }

    // Congelamiento: tinte azul en el tablero y en la pieza congelada
    if (engine.isFrozen) {
      canvas.drawRect(
        g.boardRect,
        Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.08),
      );
      if (current != null) {
        final ice = Paint()..color = const Color(0xFF7DD3FC).withValues(alpha: 0.5);
        for (final (c, r) in current.cells) {
          if (r < 0) continue;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              g.cellRect(c, r).deflate(cell * 0.05),
              Radius.circular(cell * 0.18),
            ),
            ice,
          );
        }
      }
    }

    // Cursor del poder (Rayo: fila completa; Bomba: área de 3x3)
    if (engine.status == GameStatus.targeting) {
      _paintTarget(canvas, g);
    }
  }

  void _paintTarget(Canvas canvas, TetrisGeometry g) {
    final power = engine.targetPower;
    if (power == null) return;

    final Rect area;
    final Color color;
    if (power == PowerType.lightning) {
      area = Rect.fromLTWH(
        g.origin.dx,
        g.origin.dy + engine.targetRow * g.cell,
        g.width,
        g.cell,
      );
      color = const Color(0xFFFACC15);
    } else {
      final r0 = math.max(0, engine.targetRow - 1);
      final r1 = math.min(TetrisConfig.rows - 1, engine.targetRow + 1);
      final c0 = math.max(0, engine.targetCol - 1);
      final c1 = math.min(TetrisConfig.columns - 1, engine.targetCol + 1);
      area = Rect.fromLTRB(
        g.cellRect(c0, r0).left,
        g.cellRect(c0, r0).top,
        g.cellRect(c1, r1).right,
        g.cellRect(c1, r1).bottom,
      );
      color = const Color(0xFFFB923C);
    }

    canvas.drawRect(area, Paint()..color = color.withValues(alpha: 0.28));
    canvas.drawRect(
      area,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant TetrisBoardPainter oldDelegate) =>
      oldDelegate.engine != engine;
}

/// Dibuja la pieza siguiente centrada en su recuadro.
class NextPiecePainter extends CustomPainter {
  NextPiecePainter(this.engine) : super(repaint: engine);

  final TetrisEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final type = engine.nextType;
    final m = TetrisShapes.matrix(type, 0);

    var minR = m.length, maxR = -1, minC = m.length, maxC = -1;
    for (var r = 0; r < m.length; r++) {
      for (var c = 0; c < m[r].length; c++) {
        if (m[r][c] != 1) continue;
        minR = math.min(minR, r);
        maxR = math.max(maxR, r);
        minC = math.min(minC, c);
        maxC = math.max(maxC, c);
      }
    }

    final cell = math.min(size.width, size.height) / 4.6;
    final w = (maxC - minC + 1) * cell;
    final h = (maxR - minR + 1) * cell;
    final dx = (size.width - w) / 2;
    final dy = (size.height - h) / 2;

    for (var r = minR; r <= maxR; r++) {
      for (var c = minC; c <= maxC; c++) {
        if (m[r][c] != 1) continue;
        final rect = Rect.fromLTWH(
          dx + (c - minC) * cell,
          dy + (r - minR) * cell,
          cell,
          cell,
        );
        paintTetrisCell(canvas, rect, TetrisColors.of(type));
      }
    }
  }

  @override
  bool shouldRepaint(covariant NextPiecePainter oldDelegate) =>
      oldDelegate.engine != engine;
}

// =================================================================
// Efectos visuales de los poderes
// =================================================================

/// Estado de la animación del último poder usado.
class PowerFx extends ChangeNotifier {
  static const double durationMs = 550;

  PowerEvent? event;
  double progress = 1;

  void start(PowerEvent e) {
    event = e;
    progress = 0;
    notifyListeners();
  }

  void advance(double dtMs) {
    if (event == null || progress >= 1) return;
    progress = math.min(1, progress + dtMs / durationMs);
    notifyListeners();
  }
}

/// Dibuja destellos, ondas y anillos sobre el tablero.
class PowerFxPainter extends CustomPainter {
  PowerFxPainter(this.fx) : super(repaint: fx);

  final PowerFx fx;

  @override
  void paint(Canvas canvas, Size size) {
    final e = fx.event;
    final t = fx.progress;
    if (e == null || t >= 1) return;

    final g = TetrisGeometry.of(size);
    final fade = 1 - t;
    final center = g.cellRect(e.col, e.row).center;

    canvas.save();
    canvas.clipRect(g.boardRect);

    switch (e.type) {
      case PowerType.lightning:
        final h = g.cell * (0.8 + 1.2 * t);
        final y = g.cellRect(0, e.row).center.dy;
        final bar = Rect.fromLTWH(g.origin.dx, y - h / 2, g.width, h);
        canvas.drawRect(
          bar.inflate(g.cell * 0.4),
          Paint()
            ..color = const Color(0xFFFACC15).withValues(alpha: 0.35 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.cell * 0.5),
        );
        canvas.drawRect(
          bar,
          Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.9 * fade),
        );
      case PowerType.bomb:
        final radius = g.cell * (1.2 + 3.0 * t);
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFFFB923C).withValues(alpha: 0.35 * fade),
        );
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = g.cell * 0.2 * fade + 1
            ..color = const Color(0xFFFEF08A).withValues(alpha: fade),
        );
      case PowerType.freeze:
        _ring(canvas, center, g.cell * (1 + 3 * t), const Color(0xFF7DD3FC), fade);
      case PowerType.divine:
        _ring(canvas, center, g.cell * (1 + 3 * t), const Color(0xFFFDE047), fade);
        canvas.drawCircle(
          center,
          g.cell * (0.8 + 1.5 * t),
          Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: 0.5 * fade),
        );
    }

    canvas.restore();
  }

  void _ring(Canvas canvas, Offset center, double radius, Color color, double fade) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade + 1
        ..color = color.withValues(alpha: fade),
    );
  }

  @override
  bool shouldRepaint(covariant PowerFxPainter oldDelegate) =>
      oldDelegate.fx != fx;
}