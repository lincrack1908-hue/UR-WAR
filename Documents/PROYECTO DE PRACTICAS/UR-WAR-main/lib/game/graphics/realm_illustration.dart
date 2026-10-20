import 'dart:math';
import 'package:flutter/material.dart';
import 'pixel_art_data.dart';

/// Resolution-independent actors and architecture. All geometry uses smooth
/// paths and gradients; pose changes use continuous phases, not pixel frames.
class RealmIllustration {
  static void draw(Canvas c, Size size, PixelSpriteData data) {
    c.save();
    c.scale(size.width / 100, size.height / 120);
    final art = _Illustrator(c);
    final id = data.visualId;
    if (id.contains('Tree')) {
      art.tree(id == 'snowTree');
    } else if ([
      'townHall',
      'watchtower',
      'cottage',
      'crystalMine',
      'thunderTower',
      'stoneWall',
    ].contains(id)) {
      art.building(id);
    } else if (id == 'magmaDragon') {
      art.dragon(data.phase);
    } else if (id.contains('potion') ||
        [
          'crystalGem',
          'goldCoin',
          'treasureChest',
          'legendarySword',
          'royalShield',
          'spellBook',
        ].contains(id)) {
      art.relic(id);
    } else {
      art.actor(data);
    }
    c.restore();
  }
}

class _Illustrator {
  final Canvas c;
  _Illustrator(this.c);
  static const gold = Color(0xFFC7AD79),
      ink = Color(0xFF121617),
      steel = Color(0xFF899A9A);
  void shape(List<Offset> pts, Color color, {bool outline = true}) {
    final p = Path()..addPolygon(pts, true);
    c.drawPath(p, Paint()..color = color);
    if (outline) {
      c.drawPath(
        p,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void path(Path p, Color color) {
    c.drawPath(p, Paint()..color = color);
    c.drawPath(
      p,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  void line(
    double x,
    double y,
    double xx,
    double yy,
    Color color,
    double width,
  ) => c.drawLine(
    Offset(x, y),
    Offset(xx, yy),
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void oval(double x, double y, double w, double h, Color color) => c.drawOval(
    Rect.fromCenter(center: Offset(x, y), width: w, height: h),
    Paint()..color = color,
  );
  void rect(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    double radius = 2,
  }) => c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
    Paint()..color = color,
  );
  void shade(Rect r, Color a, Color b) => c.drawRRect(
    RRect.fromRectAndRadius(r, const Radius.circular(3)),
    Paint()..shader = LinearGradient(colors: [a, b]).createShader(r),
  );

  void actor(PixelSpriteData d) {
    final id = d.visualId;
    final knight = id.startsWith('knight');
    final ranger = id.startsWith('ranger');
    final mage = id.startsWith('mage') || id == 'necromancer' || id == 'lich';
    final cleric = id == 'clericIdle';
    final goblin = id == 'goblin',
        troll = id == 'troll',
        orc = id == 'orc' || id == 'troll',
        skeleton = id == 'skeleton';
    final boss = id == 'bossTitan', ghost = id == 'frostWraith';
    final npc = id.startsWith('npc');
    final body = knight
        ? const Color(0xFF6D7C80)
        : ranger
        ? const Color(0xFF3D5140)
        : mage
        ? const Color(0xFF564362)
        : cleric
        ? const Color(0xFFDED6BC)
        : ghost
        ? const Color(0xFF819CA4)
        : boss
        ? const Color(0xFF5D5148)
        : troll
        ? const Color(0xFF5B7388)
        : orc
        ? const Color(0xFF556244)
        : goblin
        ? const Color(0xFF687050)
        : skeleton
        ? const Color(0xFFBCB7A1)
        : const Color(0xFF786749);
    final cape = knight ? const Color(0xFF692F2E) : Color.lerp(body, ink, .4)!;
    final gait = d.moving ? sin(d.phase) * 9 : 0.0;
    final sway = sin(d.phase * .7) * (d.moving ? 5 : 1.5);
    final bob = d.moving ? cos(d.phase * 2) * 1.4 : sin(d.phase) * .7;
    c.save();
    c.translate(0, bob);
    // Cloaks trail behind the shoulder line, with independently moving hem.
    path(
      Path()
        ..moveTo(33, 37)
        ..quadraticBezierTo(20 + sway, 62, 17 + sway, 105)
        ..quadraticBezierTo(45, 96, 77 + sway, 107)
        ..quadraticBezierTo(80, 58, 66, 37)
        ..close(),
      cape,
    );
    for (var i = 0; i < 4; i++) {
      line(
        36 + i * 8,
        48,
        28 + i * 13 + sway,
        98,
        Color.lerp(cape, Colors.white, .12)!,
        1,
      );
    }
    // Independent leg cycles and metal greaves.
    line(42, 76, 37 - gait * .35, 99 + gait, ink, 13);
    line(58, 76, 63 + gait * .35, 99 - gait, ink, 13);
    line(40, 84, 37 - gait * .35, 100 + gait, body, 8);
    line(60, 84, 63 + gait * .35, 100 - gait, body, 8);
    oval(35 - gait * .35, 108 + gait, 19, 9, const Color(0xFF292B29));
    oval(65 + gait * .35, 108 - gait, 19, 9, const Color(0xFF292B29));
    final torso = Rect.fromLTWH(
      boss || orc ? 27 : 33,
      40,
      boss || orc ? 46 : 34,
      42,
    );
    shade(
      torso,
      Color.lerp(body, Colors.white, .23)!,
      Color.lerp(body, ink, .3)!,
    );
    if (mage || cleric || ghost) {
      shape([
        const Offset(34, 65),
        const Offset(66, 65),
        Offset(76 + sway, 107),
        const Offset(49, 101),
        Offset(24 + sway, 108),
      ], body);
      line(45, 66, 40 + sway, 101, gold, 1.4);
      line(56, 66, 64 + sway, 102, gold, 1.4);
    }
    if (knight || boss || orc) {
      shape([
        const Offset(34, 43),
        const Offset(50, 39),
        const Offset(66, 43),
        const Offset(62, 66),
        const Offset(50, 73),
        const Offset(38, 66),
      ], body);
      line(50, 43, 50, 68, Color.lerp(body, Colors.white, .6)!, 1.2);
      for (var i = 0; i < 3; i++) {
        line(36, 70 + i * 4, 64, 70 + i * 4, ink, 1.3);
      }
    }
    rect(31, 74, 38, 5, const Color(0xFF3D3128));
    rect(47, 73, 7, 7, gold, radius: 1);
    final arm = d.attacking ? -22.0 : gait * .5;
    line(33, 46, 24, 65 - gait * .35, body, 12);
    line(24, 65 - gait * .35, 25, 77 - gait * .5, body, 8);
    line(67, 46, 78, 63 + arm, body, 12);
    line(78, 63 + arm, 80, 77 + arm, body, 8);
    oval(25, 79 - gait * .5, 9, 10, const Color(0xFFA88E72));
    oval(80, 79 + arm, 9, 10, const Color(0xFFA88E72));
    // Rounded pauldrons with thin metallic edges.
    oval(32, 46, 19, 13, body);
    oval(68, 46, 19, 13, body);
    line(25, 44, 37, 42, gold, 1.3);
    line(63, 42, 74, 45, gold, 1.3);
    if (knight || boss) {
      path(
        Path()
          ..moveTo(14, 60)
          ..lineTo(36, 56)
          ..lineTo(39, 79)
          ..quadraticBezierTo(28, 96, 20, 96)
          ..quadraticBezierTo(12, 78, 14, 60)
          ..close(),
        const Color(0xFF383D3B),
      );
      line(25, 62, 27, 85, gold, 2);
      line(19, 71, 33, 69, gold, 1.5);
      c.save();
      c.translate(80, 76 + arm);
      c.rotate(d.attacking ? -.8 : .15);
      shape([
        const Offset(-3, 0),
        const Offset(-3, -38),
        const Offset(0, -48),
        const Offset(4, -38),
        const Offset(3, 0),
      ], steel);
      line(0, -41, 0, -2, const Color(0xFFE0DFD1), 1);
      line(-9, 0, 9, 0, gold, 3);
      line(0, 1, 0, 10, ink, 4);
      c.restore();
    } else if (ranger || skeleton) {
      final p = Path()
        ..moveTo(81, 35)
        ..quadraticBezierTo(109, 65, 81, 98);
      c.drawPath(
        p,
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      line(81, 35, d.attacking ? 68 : 82, 66, const Color(0xFFC9C6AF), .8);
      line(d.attacking ? 68 : 82, 66, 81, 98, const Color(0xFFC9C6AF), .8);
      line(72, 65, 98, 65, steel, 1.3);
    } else if (mage || cleric || ghost) {
      line(83, 28 + arm, 82, 110, const Color(0xFF786443), 4);
      final glow = cleric
          ? gold
          : ghost
          ? const Color(0xFFA1D1DB)
          : const Color(0xFFBE9875);
      oval(83, 26 + arm, 23, 23, glow.withValues(alpha: .14));
      oval(83, 26 + arm, 12, 12, glow);
      oval(81, 23 + arm, 4, 4, const Color(0xFFFFE5B2));
      for (var i = 0; i < 4; i++) {
        final a = i * pi / 2;
        line(
          83 + cos(a) * 9,
          26 + arm + sin(a) * 9,
          83 + cos(a) * 14,
          26 + arm + sin(a) * 14,
          gold,
          1,
        );
      }
    } else if (!npc) {
      line(81, 40 + arm, 80, 100, const Color(0xFF5D4934), 4);
      shape([
        Offset(80, 40 + arm),
        Offset(97, 34 + arm),
        Offset(96, 52 + arm),
        Offset(81, 56 + arm),
      ], steel);
    }
    // Neck and face use real curves, with helmet/hood-specific silhouettes.
    rect(44, 30, 12, 14, const Color(0xFF92795D));
    oval(
      50,
      25,
      knight ? 27 : 24,
      31,
      knight
          ? steel
          : skeleton
          ? const Color(0xFFD0C9AF)
          : goblin || orc
          ? body
          : const Color(0xFFB59C7D),
    );
    if (knight || boss) {
      path(
        Path()
          ..moveTo(35, 27)
          ..quadraticBezierTo(32, 8, 50, 7)
          ..quadraticBezierTo(70, 9, 66, 29)
          ..lineTo(59, 38)
          ..lineTo(50, 41)
          ..lineTo(39, 35)
          ..close(),
        body,
      );
      line(38, 24, 62, 24, ink, 4);
      line(50, 10, 50, 36, gold, 1.4);
      for (var i = 0; i < 4; i++) {
        line(42 + i * 5, 29, 42 + i * 5, 33, ink, 1);
      }
      path(
        Path()
          ..moveTo(47, 9)
          ..quadraticBezierTo(51, -4, 66, 2)
          ..quadraticBezierTo(72, 9, 76, 17)
          ..quadraticBezierTo(59, 7, 53, 12)
          ..close(),
        const Color(0xFF813D34),
      );
    } else if (ranger || mage || ghost) {
      path(
        Path()
          ..moveTo(32, 33)
          ..quadraticBezierTo(27, 14, 47, 4)
          ..quadraticBezierTo(70, 7, 69, 34)
          ..lineTo(61, 40)
          ..lineTo(60, 21)
          ..quadraticBezierTo(49, 15, 39, 22)
          ..lineTo(39, 39)
          ..close(),
        body,
      );
    } else if (cleric) {
      path(
        Path()
          ..moveTo(34, 38)
          ..quadraticBezierTo(26, 8, 47, 7)
          ..quadraticBezierTo(70, 5, 68, 37)
          ..lineTo(61, 31)
          ..lineTo(60, 17)
          ..lineTo(39, 20)
          ..lineTo(40, 38)
          ..close(),
        const Color(0xFFC6BFA0),
      );
      line(37, 18, 64, 16, gold, 3);
      oval(51, 16, 5, 7, gold);
    } else if (goblin || orc) {
      shape([
        const Offset(39, 18),
        const Offset(23, 11),
        const Offset(33, 31),
      ], body);
      shape([
        const Offset(61, 18),
        const Offset(77, 11),
        const Offset(67, 31),
      ], body);
    }
    if (!d.facingAway && !knight && !boss) {
      line(42, 26, 46, 26, ink, 2);
      line(55, 26, 59, 26, ink, 2);
      line(47, 34, 55, 34, const Color(0xFF644F3D), 1.2);
    }
    if (npc) {
      if (id == 'npcBlacksmith') {
        shape([
          const Offset(37, 49),
          const Offset(61, 49),
          const Offset(67, 87),
          const Offset(32, 87),
        ], const Color(0xFF513B2B));
        line(78, 69, 78, 93, gold, 3);
        rect(70, 64, 17, 9, steel);
        path(
          Path()
            ..moveTo(39, 31)
            ..lineTo(60, 31)
            ..quadraticBezierTo(50, 53, 39, 31),
          const Color(0xFF504231),
        );
      } else if (id == 'npcMerchant') {
        oval(50, 14, 30, 15, const Color(0xFF607054));
        rect(30, 55, 12, 23, const Color(0xFF536548));
        line(30, 46, 62, 77, gold, 2);
        oval(63, 78, 13, 15, const Color(0xFF514632));
      } else {
        path(
          Path()
            ..moveTo(40, 31)
            ..lineTo(60, 31)
            ..quadraticBezierTo(52, 61, 40, 31),
          const Color(0xFFB3B1A0),
        );
        line(81, 48, 81, 109, const Color(0xFF8B7552), 3);
      }
    }
    if (d.facingAway) oval(50, 24, 24, 28, body);
    c.restore();
  }

  void building(String id) {
    if (id == 'stoneWall') {
      for (var row = 0; row < 3; row++) {
        for (var x = 0; x < 4; x++) {
          shade(
            Rect.fromLTWH(4 + x * 23 + (row % 2) * 3, 47 + row * 18, 21, 17),
            const Color(0xFF6E7168),
            const Color(0xFF373E3B),
          );
        }
      }
      return;
    }
    final tower = id == 'watchtower' || id == 'thunderTower';
    final mine = id == 'crystalMine';
    final wall = const Color(0xFF77786B), roof = const Color(0xFF653D36);
    if (mine) {
      shape([
        const Offset(5, 104),
        const Offset(20, 55),
        const Offset(51, 33),
        const Offset(86, 57),
        const Offset(98, 104),
      ], const Color(0xFF565E59));
      path(
        Path()
          ..moveTo(28, 104)
          ..lineTo(28, 77)
          ..quadraticBezierTo(50, 46, 72, 77)
          ..lineTo(72, 104)
          ..close(),
        ink,
      );
      line(23, 72, 23, 104, gold, 5);
      line(77, 72, 77, 104, gold, 5);
      line(23, 71, 77, 71, gold, 5);
      for (var i = 0; i < 3; i++) {
        shape([
          Offset(13 + i * 29, 94),
          Offset(19 + i * 29, 75),
          Offset(27 + i * 29, 88),
          Offset(23 + i * 29, 104),
        ], const Color(0xFF899C9A));
      }
      return;
    }
    final x = tower ? 28.0 : 13.0, w = tower ? 44.0 : 74.0;
    shade(
      Rect.fromLTWH(x, tower ? 30 : 52, w, tower ? 78 : 55),
      wall,
      const Color(0xFF414944),
    );
    for (var y = tower ? 40 : 60; y < 106; y += 12) {
      line(x, y.toDouble(), x + w, y.toDouble(), const Color(0xFF404640), .8);
      for (var col = 0; col < 4; col++) {
        line(
          x + col * w / 4 + (y % 24 == 0 ? 7 : 0),
          y.toDouble(),
          x + col * w / 4 + (y % 24 == 0 ? 7 : 0),
          y + 10,
          const Color(0xFF494F46),
          .8,
        );
      }
    }
    if (tower) {
      shade(const Rect.fromLTWH(20, 26, 60, 14), const Color(0xFF989783), wall);
      for (var i = 0; i < 4; i++) {
        rect(20 + i * 17, 16, 10, 20, wall, radius: 0);
      }
      rect(45, 55, 10, 25, ink, radius: 5);
      if (id == 'thunderTower') {
        oval(50, 13, 25, 22, const Color(0x336EC3D1));
        shape([
          const Offset(50, 0),
          const Offset(59, 13),
          const Offset(50, 25),
          const Offset(41, 13),
        ], const Color(0xFF9DBFC0));
      } else {
        line(47, 16, 67, 7, gold, 3);
        line(57, 5, 57, 20, ink, 3);
      }
    } else {
      shape([
        Offset(x - 8, 55),
        const Offset(50, 16),
        Offset(x + w + 8, 55),
      ], roof);
      for (var i = 0; i < 4; i++) {
        line(
          19 + i * 7,
          49 - i * 7,
          82 - i * 7,
          49 - i * 7,
          const Color(0xFF966A50),
          1,
        );
      }
      rect(67, 22, 10, 23, const Color(0xFF666B61));
      path(
        Path()
          ..moveTo(39, 106)
          ..lineTo(39, 80)
          ..quadraticBezierTo(50, 64, 61, 80)
          ..lineTo(61, 106)
          ..close(),
        ink,
      );
      for (final wx in [23.0, 70.0]) {
        rect(wx, 66, 9, 15, const Color(0xFFDCB06D));
        line(wx + 4, 66, wx + 4, 81, ink, 1);
        line(wx, 73, wx + 9, 73, ink, 1);
      }
    }
    line(7, 109, 94, 109, const Color(0xFF393F36), 5);
    // War standard, a smooth cloth silhouette.
    line(13, 28, 13, 107, const Color(0xFFB1A080), 2);
    shape([
      const Offset(14, 29),
      const Offset(30, 32),
      const Offset(28, 55),
      const Offset(21, 49),
      const Offset(14, 53),
    ], const Color(0xFF873E36));
    line(21, 35, 21, 44, gold, 1.5);
  }

  void tree(bool snow) {
    line(48, 48, 50, 110, const Color(0xFF4A4234), 10);
    for (var i = 0; i < 5; i++) {
      final y = 17 + i * 15.0, w = 15 + i * 7.0;
      final p = Path()
        ..moveTo(50, y - 15)
        ..quadraticBezierTo(45 - w, y + 9, 50 - w - 6, y + 21)
        ..quadraticBezierTo(50, y + 12, 50 + w + 6, y + 21)
        ..quadraticBezierTo(52 + w, y + 5, 50, y - 15)
        ..close();
      path(
        p,
        snow
            ? Color.lerp(
                const Color(0xFFB8C4BD),
                const Color(0xFF5D7573),
                i / 7,
              )!
            : Color.lerp(
                const Color(0xFF52654B),
                const Color(0xFF1C322B),
                i / 6,
              )!,
      );
    }
  }

  void dragon(double phase) {
    final flap = sin(phase) * 10;
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(50, 0);
      c.scale(side, 1);
      path(
        Path()
          ..moveTo(3, 58)
          ..quadraticBezierTo(21, 29 + flap, 47, 20 + flap)
          ..lineTo(40, 70)
          ..quadraticBezierTo(26, 56, 21, 83)
          ..close(),
        const Color(0xFF713E32),
      );
      line(7, 60, 46, 23 + flap, gold, 1);
      line(7, 60, 39, 66, gold, 1);
      c.restore();
    }
    oval(50, 74, 37, 58, const Color(0xFF58423A));
    path(
      Path()
        ..moveTo(37, 64)
        ..quadraticBezierTo(25, 26, 47, 13)
        ..lineTo(69, 30)
        ..lineTo(57, 40)
        ..lineTo(64, 65)
        ..close(),
      const Color(0xFF806047),
    );
    line(41, 18, 35, 3, gold, 4);
    line(53, 19, 58, 5, gold, 4);
    oval(48, 28, 4, 4, const Color(0xFFFFB566));
    line(38, 90, 28, 113, ink, 9);
    line(60, 90, 73, 113, ink, 9);
  }

  void relic(String id) {
    if (id == 'goldCoin') {
      oval(50, 65, 55, 58, gold);
      oval(50, 65, 41, 44, const Color(0xFF927648));
      line(50, 50, 50, 80, gold, 5);
      return;
    }
    if (id == 'royalShield') {
      path(
        Path()
          ..moveTo(20, 28)
          ..lineTo(80, 28)
          ..lineTo(74, 83)
          ..quadraticBezierTo(50, 119, 26, 83)
          ..close(),
        steel,
      );
      line(50, 40, 50, 94, gold, 4);
      return;
    }
    if (id == 'legendarySword') {
      shape([
        const Offset(43, 79),
        const Offset(43, 19),
        const Offset(50, 3),
        const Offset(57, 19),
        const Offset(57, 79),
      ], steel);
      line(28, 79, 72, 79, gold, 5);
      line(50, 82, 50, 111, ink, 7);
      return;
    }
    if (id.contains('potion')) {
      rect(42, 23, 16, 20, gold);
      oval(
        50,
        74,
        45,
        60,
        id == 'potionHealth'
            ? const Color(0xFF9C4F45)
            : const Color(0xFF537A86),
      );
      oval(42, 65, 9, 25, const Color(0x66FFFFFF));
      return;
    }
    shade(const Rect.fromLTWH(13, 38, 74, 63), gold, const Color(0xFF47382C));
    line(14, 57, 86, 57, ink, 3);
    rect(44, 52, 12, 20, gold);
  }
}
