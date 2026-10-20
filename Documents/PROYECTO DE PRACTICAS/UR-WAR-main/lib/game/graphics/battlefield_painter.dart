import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/entity.dart';
import '../models/game_map.dart';
import '../models/npc_model.dart';
import '../models/player_class.dart';
import 'pixel_art_data.dart';
import 'pixel_sprite_painter.dart';
import 'sprite_animation.dart';

/// World rendering is culled to the camera and sorted by the feet of each actor.
/// HUD and controls are separate widgets, so world labels stay deliberately short.
class BattlefieldPainter extends CustomPainter {
  final GameEngine engine;
  BattlefieldPainter({required this.engine}) : super(repaint: engine);
  static const double _terrainChunkSize = 512;
  static const int _maxCachedTerrainChunks = 36;
  static final Map<(String, int, int), ui.Picture> _terrainChunks = {};

  /// Clears cached terrain chunk pictures and disposes GPU resources.
  static void clearCache() {
    for (final picture in _terrainChunks.values) {
      picture.dispose();
    }
    _terrainChunks.clear();
  }

  Rect get view => Rect.fromLTWH(
    engine.cameraOffset.dx,
    engine.cameraOffset.dy,
    engine.viewportSize.width,
    engine.viewportSize.height,
  ).inflate(120);
  bool visible(Offset p) => view.contains(p);
  static final _snowTree = SpriteAnimation.recolor(PixelArtLibrary.forestTree, {
    'g': const Color(0xFFA7CBC8),
    'G': const Color(0xFFDCEEE4),
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-engine.cameraOffset.dx, -engine.cameraOffset.dy);
    _terrain(canvas);
    _paths(canvas);
    _hazards(canvas);
    _objective(canvas);
    _destination(canvas);
    final objects = <(double, VoidCallback)>[];
    for (final o in engine.map.obstacles) {
      if (visible(o.position)) {
        objects.add((o.position.dy, () => _obstacle(canvas, o)));
      }
    }
    for (final c in engine.rivalCamps) {
      if (visible(c.position)) {
        objects.add((c.position.dy, () => _camp(canvas, c)));
      }
    }
    for (final b in engine.villageBuildings) {
      if (visible(b.position)) {
        objects.add((b.position.dy, () => _building(canvas, b)));
      }
    }
    for (final n in engine.npcs) {
      if (visible(n.position)) {
        objects.add((n.position.dy, () => _npc(canvas, n)));
      }
    }
    for (final e in engine.enemies) {
      if (!e.isDead && visible(e.position)) {
        objects.add((e.position.dy, () => _enemy(canvas, e)));
      }
    }
    for (final c in engine.corpses) {
      if (visible(c.position)) {
        objects.add((c.position.dy, () => _corpse(canvas, c)));
      }
    }
    objects.add((engine.player.position.dy, () => _player(canvas)));
    objects.sort((a, b) => a.$1.compareTo(b.$1));
    for (final object in objects) {
      object.$2();
    }
    _rollingRocks(canvas);
    _projectiles(canvas);
    final particlePaint = Paint();
    for (final p in engine.particles) {
      if (!visible(p.position)) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: p.position,
          width: p.radius * 2,
          height: p.radius * 2,
        ),
        particlePaint..color = p.color.withValues(alpha: p.opacity),
      );
    }
    _fog(canvas);
    _placement(canvas);
    // Keep only recent feedback; dozens of stacked labels obscure the action.
    for (final ft in engine.floatingTexts.skip(
      max(0, engine.floatingTexts.length - 16),
    )) {
      if (visible(ft.position)) {
        _label(
          canvas,
          ft.text,
          ft.position,
          ft.color.withValues(alpha: ft.opacity),
          size: ft.fontSize.clamp(10, 14),
          background: false,
        );
      }
    }
    canvas.restore();
    _radar(canvas, size);
  }

  void _terrain(Canvas canvas) {
    final map = engine.map;
    final firstColumn = max(0, (view.left / _terrainChunkSize).floor());
    final firstRow = max(0, (view.top / _terrainChunkSize).floor());
    final lastColumn = min(
      (map.worldWidth / _terrainChunkSize).ceil() - 1,
      (view.right / _terrainChunkSize).floor(),
    );
    final lastRow = min(
      (map.worldHeight / _terrainChunkSize).ceil() - 1,
      (view.bottom / _terrainChunkSize).floor(),
    );

    for (var row = firstRow; row <= lastRow; row++) {
      for (var column = firstColumn; column <= lastColumn; column++) {
        final key = (map.id, column, row);
        final picture =
            _terrainChunks.remove(key) ?? _createTerrainChunk(column, row);
        _terrainChunks[key] = picture;
        canvas.drawPicture(picture);
      }
    }

    while (_terrainChunks.length > _maxCachedTerrainChunks) {
      _terrainChunks.remove(_terrainChunks.keys.first)!.dispose();
    }
  }

  ui.Picture _createTerrainChunk(int column, int row) {
    final left = column * _terrainChunkSize;
    final top = row * _terrainChunkSize;
    final width = min(_terrainChunkSize, engine.map.worldWidth - left);
    final height = min(_terrainChunkSize, engine.map.worldHeight - top);
    final chunk = Rect.fromLTWH(left, top, width, height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height))
      ..clipRect(Rect.fromLTWH(0, 0, width, height))
      ..translate(-left, -top);
    _drawTerrain(canvas, chunk);
    return recorder.endRecording();
  }

  void _drawTerrain(Canvas canvas, Rect terrainBounds) {
    final map = engine.map;
    final snow = map.biome == MapBiomeType.snow;
    final lava = map.biome == MapBiomeType.lava;
    final ground = snow
        ? const Color(0xFF596967)
        : lava
        ? const Color(0xFF302A28)
        : const Color(0xFF303A2E);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, map.worldWidth, map.worldHeight),
      Paint()..color = ground,
    );
    const tile = 74.0;
    for (
      var y = max(0, (terrainBounds.top / tile).floor());
      y <
          min(
            (map.worldHeight / tile).ceil(),
            (terrainBounds.bottom / tile).ceil(),
          );
      y++
    ) {
      for (
        var x = max(0, (terrainBounds.left / tile).floor());
        x <
            min(
              (map.worldWidth / tile).ceil(),
              (terrainBounds.right / tile).ceil(),
            );
        x++
      ) {
        final seed = ((x * 73856093) ^ (y * 19349663)).abs();
        final p = Offset(x * tile + (seed % 21), y * tile + ((seed >> 4) % 21));
        final patch = Rect.fromCenter(center: p, width: 110, height: 85);
        canvas.drawOval(
          patch,
          Paint()
            ..shader = RadialGradient(
              colors: [
                (snow
                        ? const Color(0xFFC6CEC1)
                        : lava
                        ? const Color(0xFF534036)
                        : const Color(0xFF68714B))
                    .withValues(alpha: .2),
                Colors.transparent,
              ],
            ).createShader(patch),
        );
        for (var i = 0; i < 7; i++) {
          final d =
              p +
              Offset(
                ((seed >> (i * 2)) % 61).toDouble(),
                ((seed >> (i * 3)) % 57).toDouble(),
              );
          if (snow) {
            canvas.drawOval(
              Rect.fromCenter(center: d, width: 12, height: 3),
              Paint()..color = const Color(0x26D4DDD3),
            );
          } else if (lava) {
            canvas.drawLine(
              d,
              d + const Offset(9, -4),
              Paint()
                ..color = const Color(0x40584B3F)
                ..strokeWidth = 1,
            );
          } else {
            canvas.drawPath(
              Path()
                ..moveTo(d.dx - 2, d.dy + 3)
                ..quadraticBezierTo(d.dx + 1, d.dy - 7, d.dx + 5, d.dy - 6),
              Paint()
                ..color = const Color(0x456D7657)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .8,
            );
          }
        }
        if (seed % 8 == 0) {
          canvas.drawOval(
            Rect.fromCenter(center: p, width: 25, height: 11),
            Paint()..color = Colors.black.withValues(alpha: .16),
          );
          for (var i = 0; i < 3; i++) {
            canvas.drawOval(
              Rect.fromCenter(
                center: p + Offset(i * 5 - 5, i % 2 * 3),
                width: 8,
                height: 5,
              ),
              Paint()
                ..color = snow
                    ? const Color(0xFF83928A)
                    : const Color(0xFF555B48),
            );
          }
        }
      }
    }
    // Battle-worn perimeter: weathered boundary stones and war standards.
    canvas.drawRect(
      Rect.fromLTWH(5, 5, map.worldWidth - 10, map.worldHeight - 10),
      Paint()
        ..color = const Color(0xFF535447)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  void _paths(Canvas canvas) {
    final center = engine.townHall.position;
    final paint = Paint()
      ..color = engine.map.pathColor.withValues(alpha: .70)
      ..strokeWidth = 52
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      center,
      225,
      Paint()..color = engine.map.pathColor.withValues(alpha: .44),
    );
    for (final camp in engine.rivalCamps) {
      canvas.drawLine(center, camp.position, paint);
      final delta = camp.position - center;
      final count = (delta.distance / 38).floor();
      for (var i = 0; i < count; i++) {
        final p = center + delta * (i / max(1, count));
        if (!visible(p)) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 19, height: 12),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFE6D3AF).withValues(alpha: .10),
        );
      }
    }
    canvas.drawCircle(
      center,
      230,
      Paint()
        ..color = const Color(0xFFDDC79D).withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _obstacle(Canvas canvas, MapObstacle obstacle) {
    final p = obstacle.position;
    if (obstacle.type == 'tree') {
      _sprite(
        canvas,
        engine.map.biome == MapBiomeType.snow
            ? _snowTree
            : PixelArtLibrary.forestTree,
        p,
        3.2,
      );
    } else if (obstacle.type == 'lava') {
      final pulse = .65 + sin(engine.elapsedTime * 3 + p.dx) * .15;
      canvas.drawOval(
        Rect.fromCenter(
          center: p,
          width: obstacle.radius * 2,
          height: obstacle.radius * 1.45,
        ),
        Paint()..color = const Color(0xFF69352D),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: p,
          width: obstacle.radius * 1.6,
          height: obstacle.radius,
        ),
        Paint()..color = const Color(0xFFEA733F).withValues(alpha: pulse),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          p + Offset((i - 1) * 13, sin(engine.elapsedTime + i) * 5),
          4,
          Paint()..color = const Color(0xFFFBD881),
        );
      }
    } else {
      final r = obstacle.radius;
      _shadow(canvas, p, r * 1.8);
      final path = Path()
        ..moveTo(p.dx - r, p.dy)
        ..lineTo(p.dx - r * .6, p.dy - r * .7)
        ..lineTo(p.dx + r * .35, p.dy - r)
        ..lineTo(p.dx + r, p.dy - r * .15)
        ..lineTo(p.dx + r * .8, p.dy + r * .3)
        ..lineTo(p.dx - r * .55, p.dy + r * .35)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF68777D));
      canvas.drawLine(
        p + Offset(-r * .5, -r * .5),
        p + Offset(r * .2, -r * .75),
        Paint()
          ..color = const Color(0xFFAAB8B8)
          ..strokeWidth = 4,
      );
    }
  }

  void _camp(Canvas canvas, RivalCampEntity camp) {
    if (camp.isDestroyed) {
      canvas.drawOval(
        Rect.fromCenter(center: camp.position, width: 80, height: 40),
        Paint()..color = Colors.black26,
      );
      _sprite(
        canvas,
        PixelArtLibrary.stoneWall,
        camp.position,
        2,
        tint: const Color(0xFF687476),
        intensity: .5,
      );
      _label(
        canvas,
        'LIBERADO',
        camp.position - const Offset(0, 42),
        const Color(0xFF92D5B3),
        size: 9,
      );
      return;
    }
    canvas.drawCircle(
      camp.position,
      camp.radius + 10,
      Paint()..color = const Color(0xFFB56253).withValues(alpha: .18),
    );
    _sprite(
      canvas,
      PixelArtLibrary.townHall,
      camp.position,
      3.0,
      tint: camp.hitFlashTimer > 0 ? Colors.white : const Color(0xFF8E3244),
      intensity: camp.hitFlashTimer > 0 ? 0.7 : .45,
    );
    _sprite(
      canvas,
      PixelArtLibrary.stoneWall,
      camp.position + const Offset(-38, 24),
      1.8,
    );
    _sprite(
      canvas,
      PixelArtLibrary.stoneWall,
      camp.position + const Offset(38, 24),
      1.8,
    );
    _health(
      canvas,
      camp.position - const Offset(0, 57),
      78,
      camp.health,
      camp.maxHealth,
      const Color(0xFFF08476),
    );
    if ((engine.player.position - camp.position).distance < 250) {
      _label(
        canvas,
        camp.name,
        camp.position - const Offset(0, 74),
        const Color(0xFFFFB6A3),
        size: 10,
        maxWidth: 160,
      );
    }
  }

  PixelSpriteData _buildingSprite(BuildingType type) => switch (type) {
    BuildingType.townHall => PixelArtLibrary.townHall,
    BuildingType.watchtower => PixelArtLibrary.watchtower,
    BuildingType.cottage => PixelArtLibrary.cottage,
    BuildingType.barricade => PixelArtLibrary.stoneWall,
    BuildingType.goldMine => PixelArtLibrary.crystalMine,
    BuildingType.frostTower => PixelArtLibrary.thunderTower,
    BuildingType.cannonTower => PixelArtLibrary.watchtower,
  };

  void _building(Canvas canvas, VillageBuildingEntity building) {
    final hall = building.type == BuildingType.townHall;
    if (building.isDead) {
      _sprite(
        canvas,
        PixelArtLibrary.stoneWall,
        building.position,
        1.6,
        tint: Colors.grey,
        intensity: .8,
      );
      return;
    }
    final frost = building.type == BuildingType.frostTower;
    final cannon = building.type == BuildingType.cannonTower;
    final color = frost
        ? const Color(0xFF99E3F5)
        : cannon
        ? const Color(0xFFEDA468)
        : const Color(0xFFB9D990);
    _sprite(
      canvas,
      _buildingSprite(building.type),
      building.position,
      hall ? 3.3 : 2.6,
      tint: building.hitFlashTimer > 0
          ? Colors.white
          : frost
          ? const Color(0xFF7BCFE7)
          : cannon
          ? const Color(0xFFEF9863)
          : null,
      intensity: building.hitFlashTimer > 0 ? 0.75 : .35,
    );
    if (cannon) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: building.position - const Offset(0, 26),
            width: 30,
            height: 13,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF343B48),
      );
      canvas.drawCircle(
        building.position + const Offset(15, -26),
        6,
        Paint()..color = Colors.black87,
      );
    }
    if (building.health < building.maxHealth || hall) {
      _health(
        canvas,
        building.position - Offset(0, hall ? 54 : 47),
        hall ? 84 : 44,
        building.health,
        building.maxHealth,
        color,
      );
    }
    if (engine.villageShieldTimer > 0) {
      canvas.drawCircle(
        building.position,
        building.radius + 9,
        Paint()
          ..color = const Color(0xFFFDE4A1).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (building.level > 1) {
      _label(
        canvas,
        '${building.level}',
        building.position + const Offset(24, 7),
        const Color(0xFFF4D58C),
        size: 10,
      );
    }
    if (hall) {
      _label(
        canvas,
        'CORAZÓN',
        building.position - const Offset(0, 68),
        const Color(0xFFDAEADA),
        size: 9,
      );
    }
  }

  void _enemy(Canvas canvas, EnemyEntity enemy) {
    final config = enemy.config;
    final size = config.isBoss ? 3.8 : 2.6;
    final emerging = enemy.emergenceTimer > 0;
    final emergenceProgress = emerging
        ? (1 - enemy.emergenceTimer / 1.2).clamp(0.0, 1.0)
        : 1.0;
    final renderPosition =
        enemy.position + Offset(0, (1 - emergenceProgress) * 28);
    if (emerging) {
      canvas.drawOval(
        Rect.fromCenter(
          center: enemy.position + const Offset(0, 14),
          width: 58,
          height: 20,
        ),
        Paint()..color = const Color(0xFF182018).withValues(alpha: .8),
      );
      canvas.saveLayer(
        Rect.fromCenter(center: enemy.position, width: 150, height: 170),
        Paint()
          ..color = Colors.white.withValues(
            alpha: .35 + emergenceProgress * .65,
          ),
      );
    }
    final sprite = SpriteAnimation.frame(
      config.sprite,
      phase: enemy.walkPhase,
      moving: true,
      attacking: enemy.attackTimer > config.attackCooldownSeconds - .2,
    );
    _sprite(
      canvas,
      sprite,
      renderPosition,
      size,
      flip: enemy.facingLeft,
      tint: enemy.hitFlashTimer > 0
          ? Colors.white
          : enemy.slowTimer > 0
          ? const Color(0xFF9EE8EF)
          : null,
      intensity: .65,
    );
    if (emerging) canvas.restore();
    if (enemy.phase > 1) {
      canvas.drawCircle(
        enemy.position,
        config.hitRadius + 5,
        Paint()
          ..color = const Color(0xFFEFA157).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (enemy.vulnerableTimer > 0) {
      final pulse = .65 + sin(engine.elapsedTime * 12) * .25;
      canvas.drawCircle(
        enemy.position,
        config.hitRadius + 11,
        Paint()
          ..color = const Color(0xFFFFD166).withValues(alpha: pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      _label(
        canvas,
        'PUNTO DÉBIL',
        enemy.position - Offset(0, config.isBoss ? 98 : 53),
        const Color(0xFFFFD166),
        size: 9,
      );
    }
    if (enemy.health < enemy.maxHealth || config.isBoss) {
      _health(
        canvas,
        enemy.position - Offset(0, config.isBoss ? 65 : 39),
        config.isBoss ? 94 : 30,
        enemy.health,
        enemy.maxHealth,
        config.healthBarColor,
      );
    }
    if (config.isBoss) {
      _label(
        canvas,
        '${config.name} · FASE ${enemy.phase}',
        enemy.position - const Offset(0, 81),
        const Color(0xFFFFD397),
        size: 10,
        maxWidth: 190,
      );
    }
  }

  void _corpse(Canvas canvas, CorpseEntity corpse) {
    final amount = (corpse.lifeTime / corpse.maxLifeTime).clamp(0.0, 1.0);
    canvas.saveLayer(
      Rect.fromCenter(center: corpse.position, width: 160, height: 160),
      Paint()..color = Colors.white.withValues(alpha: amount),
    );
    canvas.save();
    canvas.translate(corpse.position.dx, corpse.position.dy);
    canvas.rotate((1 - amount) * .8 * (corpse.facingLeft ? -1 : 1));
    canvas.scale(1, .35 + amount * .65);
    _sprite(canvas, corpse.sprite, Offset.zero, 2.6, flip: corpse.facingLeft);
    canvas.restore();
    canvas.restore();
  }

  void _player(Canvas canvas) {
    final player = engine.player;
    final role = player.playerClass;
    final attacking = player.attackAnimTimer > 0;
    final base = attacking ? role.spriteAttack : role.spriteIdle;
    final sprite = SpriteAnimation.frame(
      base,
      phase: player.isMoving ? player.walkPhase : engine.elapsedTime * 2,
      moving: player.isMoving,
      facingAway: player.aimDirection.dy < -.55,
      attacking: attacking,
    );
    if (player.dashTimer > 0) {
      for (var i = 3; i > 0; i--) {
        final pos = player.position - player.aimDirection * (i * 12.0);
        canvas.drawOval(
          Rect.fromCenter(center: pos, width: 30, height: 17),
          Paint()..color = role.themeColor.withValues(alpha: .12 * (4 - i)),
        );
      }
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: player.position + const Offset(0, 15),
        width: 39,
        height: 19,
      ),
      Paint()
        ..color = role.themeColor.withValues(alpha: .40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _sprite(
      canvas,
      sprite,
      player.position,
      2.8,
      flip: player.aimDirection.dx < -.1,
      tint: player.hitFlashTimer > 0 ? Colors.white : null,
      intensity: .75,
    );
    final aim = player.aimDirection;
    final angle = atan2(aim.dy, aim.dx);
    canvas.save();
    canvas.translate(player.position.dx, player.position.dy);
    canvas.rotate(angle);
    if (role.isMelee) {
      if (attacking) {
        final reach = role.attackRange;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: reach * .75),
          -.65,
          1.3,
          false,
          Paint()
            ..color = role.themeColor.withValues(alpha: .5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
      }
      // The articulated actor already carries a weapon. A small direction
      // marker keeps aiming clear without drawing a second block-shaped weapon.
      canvas.drawPath(
        Path()
          ..moveTo(30, -4)
          ..lineTo(37, 0)
          ..lineTo(30, 4),
        Paint()
          ..color = const Color(0xFFCFBD91)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawLine(
        const Offset(22, 0),
        const Offset(48, 0),
        Paint()
          ..color = role.themeColor.withValues(alpha: .65)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        const Offset(51, 0),
        4,
        Paint()
          ..color = const Color(0xFFF6E2AB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      if (attacking && role.type == PlayerRoleType.mage) {
        canvas.drawCircle(
          const Offset(24, 0),
          9,
          Paint()..color = const Color(0xFFE6BFFF).withValues(alpha: .8),
        );
      }
    }
    if (player.isBlocking || player.shieldTimer > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 33),
        -.85,
        1.7,
        false,
        Paint()
          ..color = const Color(0xFFB5DBED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
    canvas.restore();
    if (player.health < player.maxHealth) {
      _health(
        canvas,
        player.position - const Offset(0, 39),
        44,
        player.health,
        player.maxHealth,
        const Color(0xFF9DD49D),
      );
    }
  }

  void _npc(Canvas canvas, NpcEntity npc) {
    _sprite(canvas, npc.sprite, npc.position, 2.5);
    final quest = npc.activeQuest;
    final near = (engine.player.position - npc.position).distance < 110;
    final completed = quest != null && quest.isCompleted && !quest.isClaimed;
    if (near || completed) {
      _label(
        canvas,
        completed ? 'RECOMPENSA' : npc.name,
        npc.position - const Offset(0, 44),
        completed ? const Color(0xFFEACD88) : npc.themeColor,
        size: 10,
        maxWidth: 125,
      );
      if (near) {
        canvas.drawCircle(
          npc.position + const Offset(0, 18),
          21,
          Paint()
            ..color = npc.themeColor.withValues(alpha: .4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    } else if (quest != null && !quest.isClaimed) {
      _label(
        canvas,
        '!',
        npc.position - const Offset(0, 39),
        const Color(0xFFEACD88),
        size: 14,
      );
    }
  }

  void _projectiles(Canvas canvas) {
    final trailPaint = Paint();
    final glowPaint = Paint();
    final fillPaint = Paint();
    final highlightPaint = Paint()..color = const Color(0xFFFFE8B7);
    final linePaint = Paint();

    for (final p in engine.projectiles) {
      if (!visible(p.position)) continue;
      final length = p.velocity.distance;
      if (length < .001) continue;
      final dir = p.velocity / length;
      canvas.drawLine(
        p.position - dir * 16,
        p.position,
        trailPaint
          ..color = p.color.withValues(alpha: .35)
          ..strokeWidth = p.radius * 2,
      );
      if (p.isExplosive) {
        canvas.drawCircle(
          p.position,
          p.radius + 3,
          glowPaint..color = p.color.withValues(alpha: .25),
        );
        canvas.drawCircle(p.position, p.radius, fillPaint..color = p.color);
        canvas.drawCircle(
          p.position - const Offset(1, 1),
          p.radius * .4,
          highlightPaint,
        );
      } else {
        canvas.drawLine(
          p.position - dir * 9,
          p.position,
          linePaint
            ..color = p.color
            ..strokeWidth = 3,
        );
        final side = Offset(-dir.dy, dir.dx) * 4;
        final path = Path()
          ..moveTo(p.position.dx + dir.dx * 4, p.position.dy + dir.dy * 4)
          ..lineTo(
            p.position.dx - dir.dx * 3 + side.dx,
            p.position.dy - dir.dy * 3 + side.dy,
          )
          ..lineTo(
            p.position.dx - dir.dx * 3 - side.dx,
            p.position.dy - dir.dy * 3 - side.dy,
          )
          ..close();
        canvas.drawPath(path, fillPaint..color = p.color);
      }
    }
  }

  void _rollingRocks(Canvas canvas) {
    for (final rock in engine.rollingRocks) {
      if (!visible(rock.position)) continue;
      final direction = rock.velocity.distance > 0
          ? rock.velocity / rock.velocity.distance
          : const Offset(1, 0);
      for (var index = 1; index <= 3; index++) {
        canvas.drawCircle(
          rock.position - direction * (index * 11.0),
          max(2.0, rock.radius * (.42 - index * .08)),
          Paint()
            ..color = const Color(0xFFB08968).withValues(alpha: .22 / index),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: rock.position + Offset(0, rock.radius * .72),
          width: rock.radius * 2.2,
          height: rock.radius * .65,
        ),
        Paint()..color = Colors.black.withValues(alpha: .34),
      );
      canvas.save();
      canvas.translate(rock.position.dx, rock.position.dy);
      canvas.rotate(rock.rotation);
      canvas.drawCircle(
        Offset.zero,
        rock.radius,
        Paint()..color = const Color(0xFF6F5142),
      );
      final facet = Path()
        ..moveTo(-rock.radius * .7, -rock.radius * .25)
        ..lineTo(-rock.radius * .1, -rock.radius * .82)
        ..lineTo(rock.radius * .72, -rock.radius * .2)
        ..lineTo(rock.radius * .5, rock.radius * .65)
        ..lineTo(-rock.radius * .55, rock.radius * .55)
        ..close();
      canvas.drawPath(facet, Paint()..color = const Color(0xFF9C7257));
      canvas.drawLine(
        Offset(-rock.radius * .6, 0),
        Offset(rock.radius * .6, 0),
        Paint()
          ..color = const Color(0xFFD6B08A)
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
  }

  void _hazards(Canvas canvas) {
    final fillPaint = Paint();
    final strokePaint = Paint();
    final arcPaint = Paint();
    final linePaint = Paint();

    for (final h in engine.hazards) {
      if (!view.inflate(h.radius).contains(h.position)) continue;
      final warning = h.isWarning;
      final pulse = .7 + sin(engine.elapsedTime * 9) * .15;
      canvas.drawCircle(
        h.position,
        h.radius,
        fillPaint..color = h.color.withValues(alpha: warning ? 0.13 : .22),
      );
      canvas.drawCircle(
        h.position,
        h.radius,
        strokePaint
          ..color = h.color.withValues(alpha: pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = warning ? 2 : 4,
      );
      if (warning) {
        canvas.drawArc(
          Rect.fromCircle(center: h.position, radius: h.radius),
          -pi / 2,
          2 * pi * h.warningProgress,
          false,
          arcPaint
            ..color = h.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        _drawHazardWarning(canvas, h);
      } else if (h.isFriendly && h.type == 'sanctuary') {
        linePaint
          ..color = h.color
          ..strokeWidth = 3;
        canvas.drawLine(
          h.position - const Offset(7, 0),
          h.position + const Offset(7, 0),
          linePaint,
        );
        canvas.drawLine(
          h.position - const Offset(0, 7),
          h.position + const Offset(0, 7),
          linePaint,
        );
      } else {
        _drawHazardImpact(canvas, h);
      }
    }
  }

  void _drawHazardWarning(Canvas canvas, HazardEntity hazard) {
    final center = hazard.position;
    final progress = hazard.warningProgress;
    final paint = Paint()
      ..color = hazard.color.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    switch (hazard.type) {
      case 'titanSlam':
        for (var ray = 0; ray < 8; ray++) {
          final angle = ray * pi / 4 + progress * .35;
          final start = Offset(cos(angle), sin(angle)) * 13;
          final end = Offset(cos(angle), sin(angle)) * hazard.radius * .82;
          canvas.drawLine(center + start, center + end, paint);
        }
        _label(canvas, '⚡', center, hazard.color, size: 22);
        break;
      case 'iceStorm':
        for (var ray = 0; ray < 6; ray++) {
          final angle = ray * pi / 3 + engine.elapsedTime * .25;
          final end = Offset(cos(angle), sin(angle)) * hazard.radius * .65;
          canvas.drawLine(center, center + end, paint);
          final branch = Offset(-sin(angle), cos(angle)) * 8;
          canvas.drawLine(
            center + end * .65,
            center + end * .48 + branch,
            paint,
          );
          canvas.drawLine(
            center + end * .65,
            center + end * .48 - branch,
            paint,
          );
        }
        break;
      case 'meteor':
        final altitude = 125 * (1 - progress);
        final meteor = center + Offset(altitude * .48, -altitude);
        canvas.drawLine(
          meteor + const Offset(35, -70),
          meteor,
          Paint()
            ..color = hazard.color.withValues(alpha: .45)
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(meteor, 13, Paint()..color = hazard.color);
        canvas.drawCircle(
          meteor - const Offset(3, 4),
          5,
          Paint()..color = Colors.white70,
        );
        break;
      case 'lavaBurst':
      case 'eruption':
        for (var ray = 0; ray < 7; ray++) {
          final angle = ray * 2 * pi / 7;
          final start = center + Offset(cos(angle), sin(angle)) * 12;
          final middle =
              center +
              Offset(cos(angle + .18), sin(angle + .18)) * hazard.radius * .5;
          final end =
              center + Offset(cos(angle), sin(angle)) * hazard.radius * .9;
          canvas.drawPath(
            Path()
              ..moveTo(start.dx, start.dy)
              ..lineTo(middle.dx, middle.dy)
              ..lineTo(end.dx, end.dy),
            paint,
          );
        }
        break;
      case 'necromancy':
      case 'graveRise':
      case 'soulLink':
        _drawNecromancyRune(canvas, hazard, progress);
        break;
      default:
        _label(
          canvas,
          hazard.isFriendly ? '+' : '!',
          center,
          hazard.color,
          size: 20,
        );
        break;
    }
  }

  void _drawHazardImpact(Canvas canvas, HazardEntity hazard) {
    final center = hazard.position;
    final progress = hazard.activeProgress;
    final paint = Paint()
      ..color = hazard.color.withValues(alpha: 1 - progress * .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    switch (hazard.type) {
      case 'titanSlam':
        for (var ring = 1; ring <= 3; ring++) {
          canvas.drawCircle(
            center,
            hazard.radius * progress * ring / 3,
            paint..strokeWidth = 7 - ring.toDouble(),
          );
        }
        break;
      case 'ice':
      case 'iceStorm':
        for (var shard = 0; shard < 10; shard++) {
          final angle = shard * pi / 5 + progress * .3;
          final length = hazard.radius * (.25 + progress * .7);
          final end = center + Offset(cos(angle), sin(angle)) * length;
          canvas.drawLine(center, end, paint..strokeWidth = 2.5);
          canvas.drawCircle(
            end,
            4 + progress * 3,
            Paint()..color = hazard.color,
          );
        }
        break;
      case 'meteor':
        canvas.drawCircle(
          center,
          hazard.radius * progress,
          Paint()..color = hazard.color.withValues(alpha: .24 * (1 - progress)),
        );
        for (var flare = 0; flare < 12; flare++) {
          final angle = flare * pi / 6;
          final end =
              center +
              Offset(cos(angle), sin(angle)) * hazard.radius * progress;
          canvas.drawLine(center, end, paint..strokeWidth = 5);
        }
        canvas.drawCircle(
          center,
          hazard.radius * (.25 + progress * .75),
          paint..strokeWidth = 5,
        );
        break;
      case 'lavaBurst':
      case 'eruption':
        for (var burst = 0; burst < 9; burst++) {
          final angle = burst * 2 * pi / 9;
          final end =
              center +
              Offset(cos(angle), sin(angle)) * hazard.radius * progress;
          canvas.drawLine(center, end, paint..strokeWidth = 5);
          canvas.drawCircle(
            end,
            4 + (1 - progress) * 5,
            Paint()..color = hazard.color,
          );
        }
        break;
      case 'necromancy':
      case 'graveRise':
      case 'soulLink':
        _drawNecromancyRune(canvas, hazard, progress);
        break;
      default:
        canvas.drawCircle(center, hazard.radius * progress, paint);
        break;
    }
  }

  void _drawNecromancyRune(
    Canvas canvas,
    HazardEntity hazard,
    double progress,
  ) {
    final paint = Paint()
      ..color = hazard.color.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.save();
    canvas.translate(hazard.position.dx, hazard.position.dy);
    canvas.rotate(engine.elapsedTime * 1.8);
    final radius = hazard.radius * (.72 + sin(engine.elapsedTime * 8) * .08);
    final rune = Path();
    for (var point = 0; point < 4; point++) {
      final angle = -pi / 2 + point * pi / 2;
      final p = Offset(cos(angle), sin(angle)) * radius;
      if (point == 0) {
        rune.moveTo(p.dx, p.dy);
      } else {
        rune.lineTo(p.dx, p.dy);
      }
    }
    rune.close();
    canvas.drawPath(rune, paint);
    canvas.drawCircle(Offset.zero, radius * .52, paint);
    canvas.drawLine(
      Offset(0, radius * .45),
      Offset(0, -radius * (.15 + progress * .55)),
      paint..strokeWidth = 4,
    );
    canvas.restore();
  }

  void _objective(Canvas canvas) {
    final pos = engine.objectivePosition;
    if (pos == null || engine.objectiveComplete) return;
    canvas.drawCircle(
      pos,
      65,
      Paint()..color = const Color(0xFFB4D9EC).withValues(alpha: .12),
    );
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 65),
      -pi / 2,
      2 * pi * engine.objectiveProgress,
      false,
      Paint()
        ..color = const Color(0xFF91D9EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    _sprite(
      canvas,
      PixelArtLibrary.thunderTower,
      pos,
      2.5,
      tint: const Color(0xFFBECBD0),
      intensity: .6,
    );
    _label(
      canvas,
      'RECUPERAR TORRE',
      pos - const Offset(0, 58),
      const Color(0xFFC6E6F3),
      size: 10,
    );
  }

  void _destination(Canvas canvas) {
    final pos = engine.player.targetDestination;
    if (pos == null) return;
    canvas.drawCircle(
      pos,
      9 + sin(engine.elapsedTime * 5) * 2,
      Paint()
        ..color = const Color(0xFFEAD49A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFFEAD49A));
  }

  void _placement(Canvas canvas) {
    final type = engine.pendingBuildingType;
    final pos = engine.buildPreviewPosition;
    if (type == null || pos == null) return;
    final valid = engine.canPlaceStructure(type, pos);
    final color = valid ? const Color(0xFF9DDCBA) : const Color(0xFFF18B8B);
    canvas.drawCircle(
      engine.townHall.position,
      430,
      Paint()
        ..color = color.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final spec = BuildingSpec.forType(type);
    if (spec.range > 0) {
      canvas.drawCircle(
        pos,
        spec.range,
        Paint()..color = color.withValues(alpha: .10),
      );
    }
    canvas.drawCircle(
      pos,
      spec.radius + 8,
      Paint()..color = color.withValues(alpha: .3),
    );
    canvas.drawCircle(
      pos,
      spec.radius + 8,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _sprite(
      canvas,
      _buildingSprite(type),
      pos,
      2.6,
      tint: color,
      intensity: .65,
    );
    _label(
      canvas,
      valid ? 'UBICACIÓN VÁLIDA' : 'ESPACIO BLOQUEADO',
      pos - const Offset(0, 65),
      color,
      size: 10,
    );
  }

  void _fog(Canvas canvas) {
    final tile = GameEngine.fogTileSize;
    final fog = Path();
    for (
      var r = max(0, (view.top / tile).floor());
      r <= min(engine.fogRows - 1, (view.bottom / tile).ceil());
      r++
    ) {
      for (
        var col = max(0, (view.left / tile).floor());
        col <= min(engine.fogCols - 1, (view.right / tile).ceil());
        col++
      ) {
        if (!engine.fogExplored[r][col]) {
          fog.addRect(Rect.fromLTWH(col * tile, r * tile, tile + 1, tile + 1));
        }
      }
    }
    canvas.drawPath(
      fog,
      Paint()
        ..color = const Color(0xD1111612)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _radar(Canvas canvas, Size size) {
    if (size.shortestSide < 160) return;
    final screen = Rect.fromLTWH(
      engine.cameraOffset.dx,
      engine.cameraOffset.dy,
      size.width,
      size.height,
    );
    final sectors = <int>{};
    for (final enemy in engine.enemies) {
      if (enemy.isDead || screen.contains(enemy.position)) continue;
      final d = enemy.position - engine.player.position;
      if (d.distance > 650) continue;
      final angle = atan2(d.dy, d.dx);
      final sector = ((angle + pi) / (pi / 6)).floor();
      if (!sectors.add(sector)) continue;
      final origin = Offset(size.width / 2, size.height / 2);
      final point =
          origin +
          Offset(
            cos(angle) * (size.width / 2 - 20),
            sin(angle) * (size.height / 2 - 115),
          );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle);
      canvas.drawPath(
        Path()
          ..moveTo(6, 0)
          ..lineTo(-4, -4)
          ..lineTo(-4, 4)
          ..close(),
        Paint()..color = const Color(0xFFFFA28E),
      );
      canvas.restore();
    }
  }

  static final _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: .25);
  static final _healthBgPaint = Paint()..color = const Color(0xFF101B25);
  final _healthFillPaint = Paint();

  void _shadow(Canvas canvas, Offset p, double width) => canvas.drawOval(
    Rect.fromCenter(
      center: p + const Offset(0, 14),
      width: width,
      height: width * .3,
    ),
    _shadowPaint,
  );

  void _sprite(
    Canvas canvas,
    PixelSpriteData sprite,
    Offset p,
    double scale, {
    bool flip = false,
    Color? tint,
    double intensity = 0,
  }) {
    final width = sprite.width * scale, height = sprite.height * scale;
    canvas.save();
    canvas.translate((p.dx - width / 2), (p.dy - height * .72));
    PixelSpritePainter(
      sprite: sprite,
      pixelSize: scale,
      flipX: flip,
      tintColor: tint,
      tintIntensity: intensity,
    ).paint(canvas, Size(width, height));
    canvas.restore();
  }

  void _health(
    Canvas canvas,
    Offset pos,
    double width,
    double hp,
    double maxHp,
    Color color,
  ) {
    if (maxHp <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: width + 2, height: 6),
        const Radius.circular(3),
      ),
      _healthBgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          pos.dx - width / 2,
          pos.dy - 2,
          width * (hp / maxHp).clamp(0, 1),
          4,
        ),
        const Radius.circular(2),
      ),
      _healthFillPaint..color = color,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset pos,
    Color color, {
    double size = 11,
    double maxWidth = 180,
    bool background = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final rect = Rect.fromCenter(
      center: pos,
      width: painter.width + 10,
      height: painter.height + 4,
    );
    if (background) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF101B25).withValues(alpha: .84),
      );
    }
    painter.paint(
      canvas,
      Offset(pos.dx - painter.width / 2, pos.dy - painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant BattlefieldPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
