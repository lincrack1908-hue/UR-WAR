import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ur_war/core/save_system.dart';
import 'package:ur_war/game/graphics/battlefield_painter.dart';
import 'package:ur_war/game/logic/game_engine.dart';
import 'package:ur_war/game/models/enemy_type.dart';
import 'package:ur_war/game/models/entity.dart';
import 'package:ur_war/game/models/game_map.dart';
import 'package:ur_war/game/models/player_class.dart';
import 'package:ur_war/game/widgets/battle_minimap.dart';
import 'package:ur_war/game/widgets/game_over_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameEngine engine;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SaveSystem.initialize();
    engine = GameEngine(
      map: GameMapModel.availableMaps.first,
      playerClass: PlayerClass.availableClasses.first,
    );
  });
  tearDown(() => engine.dispose());

  test(
    'Preparation and pause do not spawn enemies or advance the simulation',
    () {
      for (var i = 0; i < 100; i++) {
        engine.update(.1);
      }
      expect(engine.enemies, isEmpty);
      engine.startNextWave();
      engine.setPaused(true);
      final time = engine.elapsedTime;
      engine.update(.2);
      expect(engine.elapsedTime, time);
      engine.setPaused(false);
      engine.update(.2);
      expect(engine.enemies, isNotEmpty);
    },
  );
  test('Melee enemies can hit the outside edge of a building', () {
    engine.player.position = engine.townHall.position + const Offset(500, 0);
    for (final building in engine.villageBuildings) {
      if (building.type != BuildingType.townHall) building.health = 0;
    }
    engine.enemies.add(
      EnemyEntity(
        id: 'siege',
        config: EnemyConfig.orc,
        position: engine.townHall.position + const Offset(70, 0),
      ),
    );
    final hp = engine.townHall.health;
    engine.update(.05);
    expect(engine.townHall.health, lessThan(hp));
  });

  test('Skeleton archers retreat when the player gets too close', () {
    final archer = EnemyEntity(
      id: 'archer',
      config: EnemyConfig.skeleton,
      position: engine.player.position + const Offset(80, 0),
    );
    engine.enemies.add(archer);
    final initialDistance = (archer.position - engine.player.position).distance;

    engine.update(.1);

    expect(
      (archer.position - engine.player.position).distance,
      greaterThan(initialDistance),
    );
  });

  test('Necromancers heal the most wounded nearby ally', () {
    final necromancer = EnemyEntity(
      id: 'necromancer',
      config: EnemyConfig.necromancer,
      position: engine.player.position + const Offset(140, 0),
    )..abilityTimer = 0;
    final orc = EnemyEntity(
      id: 'wounded-orc',
      config: EnemyConfig.orc,
      position: necromancer.position + const Offset(30, 0),
    )..health = 20;
    engine.enemies.addAll([necromancer, orc]);

    engine.update(.05);

    expect(orc.health, greaterThan(20));
    expect(necromancer.abilityTimer, greaterThan(0));
  });

  test('Necromancers revive an ally only once', () {
    final necromancer = EnemyEntity(
      id: 'necromancer',
      config: EnemyConfig.necromancer,
      position: engine.player.position + const Offset(140, 0),
    )..abilityTimer = 0;
    engine.enemies.add(necromancer);
    engine.corpses.add(
      CorpseEntity(
        position: necromancer.position + const Offset(30, 0),
        sprite: EnemyConfig.goblin.sprite,
        config: EnemyConfig.goblin,
        facingLeft: false,
        isWaveEnemy: true,
        canBeRevived: true,
      ),
    );

    engine.update(.05);

    final revived = engine.enemies.singleWhere(
      (enemy) => enemy.config.category == EnemyCategory.goblin,
    );
    expect(revived.health, EnemyConfig.goblin.maxHealth * 0.45);
    expect(revived.canBeRevived, isFalse);
    expect(engine.corpses, isEmpty);
    expect(engine.enemiesRevived, 1);
    expect(engine.hazards.single.type, 'necromancy');
  });

  test('Necromancer miniboss raises a diamond of skeleton guards', () {
    final miniboss = EnemyEntity(
      id: 'malachar',
      config: EnemyConfig.necromancerMiniboss,
      position: engine.player.position + const Offset(500, 0),
      isWaveEnemy: true,
    )..abilityTimer = 0;
    engine.enemies.add(miniboss);

    engine.update(.05);

    final guards = engine.enemies
        .where((enemy) => enemy.guardLeaderId == miniboss.id)
        .toList();
    expect(guards, hasLength(4));
    expect(guards.map((guard) => guard.guardOffset).toSet(), {
      const Offset(0, -95),
      const Offset(95, 0),
      const Offset(0, 95),
      const Offset(-95, 0),
    });
    expect(guards.every((guard) => guard.emergenceTimer > 0), isTrue);
    expect(guards.every((guard) => !guard.grantsReward), isTrue);
    expect(guards.every((guard) => !guard.canBeRevived), isTrue);
    expect(engine.enemiesRevived, 4);
    expect(
      engine.hazards.where((hazard) => hazard.type == 'graveRise'),
      hasLength(4),
    );
  });

  test('Final titan alternates seismic strike and rolling rocks', () {
    final titan = EnemyEntity(
      id: 'final-titan',
      config: EnemyConfig.bossTitan,
      position: engine.player.position + const Offset(500, 0),
    )..abilityTimer = 0;
    engine.enemies.add(titan);

    engine.update(.05);
    expect(engine.hazards.any((hazard) => hazard.type == 'titanSlam'), isTrue);
    expect(titan.vulnerableTimer, greaterThan(0));

    titan.health = titan.maxHealth * .4;
    titan.abilityTimer = 0;
    engine.update(.05);
    expect(titan.phase, 2);
    expect(engine.rollingRocks, hasLength(5));
    expect(engine.announcementBanner, contains('AVALANCHA'));
  });

  test('Rolling rocks damage the player and break on impact', () {
    final health = engine.player.health;
    engine.rollingRocks.add(
      RollingRockEntity(
        position: engine.player.position,
        velocity: Offset.zero,
        damage: 24,
      ),
    );

    engine.update(.05);

    expect(engine.player.health, health - 24);
    expect(engine.damageTaken, 24);
    expect(engine.rollingRocks, isEmpty);
  });

  test('Boss weak points amplify damage and contribute to result stats', () {
    final enemy = EnemyEntity(
      id: 'weak-target',
      config: EnemyConfig.orc,
      position: engine.player.position + const Offset(100, 0),
    )..vulnerableTimer = 1;
    engine.enemies.add(enemy);
    final health = enemy.health;
    engine.projectiles.add(
      ProjectileEntity(
        position: enemy.position,
        velocity: Offset.zero,
        damage: 10,
        color: Colors.white,
        isFromPlayer: true,
      ),
    );

    engine.update(.05);

    expect(enemy.health, health - 15);
    expect(engine.damageDealt, 15);
  });

  test('Later waves apply progressive enemy scaling', () {
    engine.waveSystem.startWave(
      4,
      engine.map.worldWidth,
      engine.map.worldHeight,
    );

    engine.update(.05);

    final miniboss = engine.enemies.singleWhere(
      (enemy) => enemy.config.category == EnemyCategory.necromancerMiniboss,
    );
    expect(
      miniboss.maxHealth,
      closeTo(EnemyConfig.necromancerMiniboss.maxHealth * 1.24, .001),
    );
    expect(miniboss.damageScale, closeTo(1.18, .001));
    expect(miniboss.speedScale, closeTo(1.045, .001));
  });

  test('Boss phase transition is clearly announced', () {
    final miniboss = EnemyEntity(
      id: 'phase-boss',
      config: EnemyConfig.necromancerMiniboss,
      position: engine.player.position + const Offset(500, 0),
    );
    miniboss.health = miniboss.maxHealth * .4;
    miniboss.abilityTimer = 5;
    engine.enemies.add(miniboss);

    engine.update(.05);

    expect(miniboss.phase, 2);
    expect(engine.announcementBanner, contains('FASE 2'));
  });

  test('Invalid and cancelled construction never charge gold', () {
    final gold = engine.player.gold;
    expect(engine.beginConstruction(BuildingType.watchtower, 100), isTrue);
    engine.setBuildPreview(engine.townHall.position);
    expect(engine.confirmConstruction(), isFalse);
    expect(engine.player.gold, gold);
    engine.cancelConstruction();
    expect(engine.pendingBuildingType, isNull);
    expect(engine.player.gold, gold);
    expect(engine.beginConstruction(BuildingType.watchtower, 1), isFalse);
  });
  test('A piercing projectile cannot damage the same target every frame', () {
    final enemy = EnemyEntity(
      id: 'test',
      config: EnemyConfig.orc,
      position: engine.player.position + const Offset(100, 0),
    );
    engine.enemies.add(enemy);
    final hp = enemy.health;
    engine.projectiles.add(
      ProjectileEntity(
        position: enemy.position,
        velocity: Offset.zero,
        damage: 10,
        color: Colors.white,
        isFromPlayer: true,
        pierceCount: 3,
      ),
    );
    engine.update(.1);
    expect(enemy.health, hp - 10);
  });
  test('Hazards warn before damage and dodge protects the player', () {
    final hp = engine.player.health;
    engine.hazards.add(
      HazardEntity(
        position: engine.player.position,
        radius: 100,
        damage: 30,
        color: Colors.red,
        delay: .2,
      ),
    );
    engine.update(.1);
    expect(engine.player.health, hp);
    engine.player.shieldTimer = 1;
    engine.update(.2);
    expect(engine.player.health, hp);
  });
  test('Profile persists settings and keeps best campaign results', () async {
    SaveSystem.setMusicVolume(.2);
    SaveSystem.completeLevel('test', levelNumber: 1, stars: 3, score: 500);
    SaveSystem.completeLevel('test', levelNumber: 1, stars: 1, score: 100);
    await SaveSystem.flush();
    await SaveSystem.initialize();
    expect(SaveSystem.data.musicVolume, .2);
    expect(SaveSystem.starsFor('test'), 3);
    expect(SaveSystem.data.levelScores['test'], 500);
    expect(SaveSystem.isLevelUnlocked(2), isTrue);
  });

  test('Level 1 tutorial hints are queued and can be restored', () async {
    expect(engine.activeTutorialHint?.id, 'level1_welcome');

    engine.startNextWave();
    engine.update(.2);
    engine.dismissTutorialHint();
    expect(engine.activeTutorialHint?.id, 'level1_first_wave');
    engine.dismissTutorialHint();
    expect(engine.activeTutorialHint?.id, 'level1_goblin');

    engine.disableTutorialHints();
    expect(SaveSystem.tutorialHintsEnabled, isFalse);
    expect(engine.activeTutorialHint, isNull);

    SaveSystem.resetTutorialHints();
    await SaveSystem.flush();
    expect(SaveSystem.tutorialHintsEnabled, isTrue);
    expect(SaveSystem.hasSeenTutorialHint('level1_welcome'), isFalse);
  });

  test('Reactive hints explain danger, cooldowns and missing gold', () {
    engine.dismissTutorialHint();

    engine.player.health = engine.player.maxHealth * .4;
    engine.projectiles.add(
      ProjectileEntity(
        position: engine.player.position,
        velocity: Offset.zero,
        damage: engine.player.maxHealth * .1,
        color: Colors.red,
        isFromPlayer: false,
      ),
    );
    engine.update(.05);
    expect(engine.activeTutorialHint?.id, 'level1_low_health');
    engine.dismissTutorialHint();

    engine.player.position = engine.townHall.position + const Offset(500, 0);
    for (final building in engine.villageBuildings) {
      if (building.type != BuildingType.townHall) building.health = 0;
    }
    engine.enemies.add(
      EnemyEntity(
        id: 'tutorial-siege',
        config: EnemyConfig.orc,
        position: engine.townHall.position + const Offset(70, 0),
      ),
    );
    engine.update(.05);
    expect(engine.activeTutorialHint?.id, 'level1_town_hall_under_attack');
    engine.dismissTutorialHint();

    engine.player.gold = 0;
    expect(engine.beginConstruction(BuildingType.watchtower, 100), isFalse);
    expect(engine.activeTutorialHint?.id, 'level1_insufficient_gold');
    engine.dismissTutorialHint();

    engine.player.specialSkillTimer = .02;
    engine.useSpecialSkill();
    expect(engine.activeTutorialHint?.id, 'level1_special_cooldown');
    engine.dismissTutorialHint();
    engine.update(.05);
    expect(engine.activeTutorialHint?.id, 'level1_special_ready');
  });

  test('Every level 1 construction has a contextual item card', () {
    engine.dismissTutorialHint();
    final expected = {
      BuildingType.watchtower: 'level1_item_watchtower',
      BuildingType.frostTower: 'level1_item_frost_tower',
      BuildingType.cannonTower: 'level1_item_cannon',
      BuildingType.barricade: 'level1_item_barricade',
      BuildingType.goldMine: 'level1_item_gold_mine',
    };

    for (final entry in expected.entries) {
      engine.showTutorialForBuildingType(entry.key);
      expect(engine.activeTutorialHint?.id, entry.value);
      engine.dismissTutorialHint();
    }
  });

  test(
    'BattlefieldPainter paints terrain and clearCache disposes resources cleanly',
    () {
      for (final type in [
        'titanSlam',
        'iceStorm',
        'lavaBurst',
        'meteor',
        'graveRise',
      ]) {
        engine.hazards.add(
          HazardEntity(
            position: engine.player.position,
            radius: 80,
            damage: 10,
            color: Colors.purpleAccent,
            type: type,
            delay: 0,
          ),
        );
      }
      engine.rollingRocks.add(
        RollingRockEntity(
          position: engine.player.position,
          velocity: const Offset(200, 0),
          damage: 20,
        ),
      );
      final painter = BattlefieldPainter(engine: engine);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
      expect(() => BattlefieldPainter.clearCache(), returnsNormally);
    },
  );

  testWidgets('Minimap renders role icons without adding a separate legend', (
    tester,
  ) async {
    engine.enemies.addAll([
      EnemyEntity(
        id: 'map-ranged',
        config: EnemyConfig.skeleton,
        position: engine.player.position,
      ),
      EnemyEntity(
        id: 'map-support',
        config: EnemyConfig.necromancer,
        position: engine.player.position + const Offset(10, 0),
      ),
      EnemyEntity(
        id: 'map-boss',
        config: EnemyConfig.bossTitan,
        position: engine.player.position + const Offset(20, 0),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BattleMinimap(engine: engine)),
      ),
    );

    expect(find.byType(BattleMinimap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Battle results remain usable on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    engine.isVictory = true;
    engine.completedWaves = engine.map.totalWaves;
    engine.damageDealt = 1234;
    engine.damageTaken = 120;
    engine.enemiesRevived = 4;
    engine.bossesDefeated = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameOverDialog(engine: engine, onRestart: () {}, onExit: () {}),
        ),
      ),
    );

    expect(find.text('RESULTADOS DE BATALLA'), findsOneWidget);
    expect(find.text('Jefes derrotados'), findsOneWidget);
    expect(find.text('Enemigos resucitados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
