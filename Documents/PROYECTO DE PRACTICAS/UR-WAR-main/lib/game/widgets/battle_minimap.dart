import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/enemy_type.dart';

class BattleMinimap extends StatelessWidget {
  final GameEngine engine;
  final double width;
  const BattleMinimap({super.key, required this.engine, this.width = 108});

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Minimapa: tú en blanco, aldea azul, campamentos rojos e iconos enemigos por rol',
    child: IgnorePointer(
      child: Container(
        width: width,
        height: width * .75,
        decoration: BoxDecoration(
          color: const Color(0xDD111711),
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: _MinimapPainter(engine)),
      ),
    ),
  );
}

class _MinimapPainter extends CustomPainter {
  final GameEngine engine;
  _MinimapPainter(this.engine) : super(repaint: engine);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / engine.map.worldWidth;
    final sy = size.height / engine.map.worldHeight;
    Offset point(Offset p) => Offset(p.dx * sx, p.dy * sy);
    bool visible(Offset p) {
      final col = (p.dx / GameEngine.fogTileSize).floor().clamp(
        0,
        engine.fogCols - 1,
      );
      final row = (p.dy / GameEngine.fogTileSize).floor().clamp(
        0,
        engine.fogRows - 1,
      );
      return engine.fogExplored[row][col];
    }

    final paint = Paint()..color = engine.map.groundAccentColor;
    for (var r = 0; r < engine.fogRows; r++) {
      for (var c = 0; c < engine.fogCols; c++) {
        if (engine.fogExplored[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * 100 * sx,
              r * 100 * sy,
              100 * sx + 1,
              100 * sy + 1,
            ),
            paint,
          );
        }
      }
    }
    for (final building in engine.villageBuildings.where((b) => !b.isDead)) {
      canvas.drawCircle(
        point(building.position),
        2.4,
        Paint()..color = Colors.lightBlueAccent,
      );
    }
    for (final camp in engine.rivalCamps.where((c) => !c.isDestroyed)) {
      // Camp locations are strategic intelligence; fog hides roaming enemies.
      canvas.drawRect(
        Rect.fromCenter(center: point(camp.position), width: 4, height: 4),
        Paint()..color = Colors.redAccent,
      );
    }
    for (final enemy in engine.enemies.where(
      (e) => !e.isDead && visible(e.position),
    )) {
      _drawEnemyIcon(canvas, point(enemy.position), enemy.config);
    }
    canvas.drawRect(
      Rect.fromLTWH(
        engine.cameraOffset.dx * sx,
        engine.cameraOffset.dy * sy,
        engine.viewportSize.width * sx,
        engine.viewportSize.height * sy,
      ),
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      point(engine.player.position),
      3,
      Paint()..color = Colors.white,
    );
  }

  void _drawEnemyIcon(Canvas canvas, Offset center, EnemyConfig config) {
    if (config.isBoss) {
      final path = Path()
        ..moveTo(center.dx, center.dy - 4)
        ..lineTo(center.dx + 4, center.dy)
        ..lineTo(center.dx, center.dy + 4)
        ..lineTo(center.dx - 4, center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.redAccent);
      canvas.drawCircle(center, 1.2, Paint()..color = Colors.white);
      return;
    }
    switch (config.behavior) {
      case EnemyBehavior.support:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 2, height: 6),
          Paint()..color = Colors.lightGreenAccent,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 6, height: 2),
          Paint()..color = Colors.lightGreenAccent,
        );
        break;
      case EnemyBehavior.siege:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 4, height: 4),
          Paint()..color = Colors.deepOrangeAccent,
        );
        break;
      case EnemyBehavior.rangedKiter:
        final path = Path()
          ..moveTo(center.dx, center.dy - 3)
          ..lineTo(center.dx + 3, center.dy + 2.5)
          ..lineTo(center.dx - 3, center.dy + 2.5)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.amberAccent);
        break;
      case EnemyBehavior.raider:
      case EnemyBehavior.miniboss:
        canvas.drawCircle(
          center,
          config.behavior == EnemyBehavior.miniboss ? 3 : 2,
          Paint()..color = Colors.orangeAccent,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
