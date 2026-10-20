import 'package:flutter_test/flutter_test.dart';
import 'package:ur_war/game/logic/enemy_ai.dart';
import 'package:ur_war/game/models/enemy_type.dart';
import 'package:ur_war/game/models/entity.dart';

void main() {
  test('enemy configurations expose distinct AI behavior roles', () {
    expect(EnemyConfig.goblin.behavior, EnemyBehavior.raider);
    expect(EnemyConfig.orc.behavior, EnemyBehavior.raider);
    expect(EnemyConfig.troll.behavior, EnemyBehavior.siege);
    expect(EnemyConfig.skeleton.behavior, EnemyBehavior.rangedKiter);
    expect(EnemyConfig.necromancer.behavior, EnemyBehavior.support);
    expect(
      EnemyConfig.necromancerMiniboss.ability,
      EnemyAbility.diamondResurrection,
    );
    expect(EnemyConfig.bossTitan.behavior, EnemyBehavior.miniboss);
  });

  test('ranged and support roles define future tactical ranges', () {
    final archer = EnemyConfig.skeleton;
    final necromancer = EnemyConfig.necromancer;

    expect(archer.preferredRange, greaterThan(archer.retreatRange));
    expect(necromancer.preferredRange, greaterThan(necromancer.retreatRange));
    expect(necromancer.targetPriorities.first, TargetPriority.fallenAlly);
    expect(necromancer.abilityCooldownSeconds, greaterThan(0));
  });

  test(
    'target selections identify players and buildings without ambiguity',
    () {
      const playerPosition = Offset(40, 80);
      final playerTarget = EnemyTargetSelection.player(playerPosition);
      expect(playerTarget.targetsPlayer, isTrue);
      expect(playerTarget.building, isNull);
      expect(playerTarget.position, playerPosition);

      final building = VillageBuildingEntity(
        id: 'test-tower',
        type: BuildingType.watchtower,
        position: const Offset(120, 160),
        maxHealth: 500,
        radius: 35,
      );
      final buildingTarget = EnemyTargetSelection.building(building);
      expect(buildingTarget.targetsPlayer, isFalse);
      expect(buildingTarget.building, same(building));
      expect(buildingTarget.distanceFrom(const Offset(120, 60)), 100);
    },
  );

  group('siege targeting', () {
    late VillageBuildingEntity townHall;
    late VillageBuildingEntity nearDefense;
    late VillageBuildingEntity farDefense;
    late EnemyEntity troll;

    setUp(() {
      townHall = _building(
        id: 'town-hall',
        type: BuildingType.townHall,
        position: const Offset(400, 0),
      );
      nearDefense = _building(
        id: 'near-tower',
        type: BuildingType.watchtower,
        position: const Offset(220, 0),
      );
      farDefense = _building(
        id: 'far-tower',
        type: BuildingType.cannonTower,
        position: const Offset(300, 0),
      );
      troll = EnemyEntity(
        id: 'troll',
        config: EnemyConfig.troll,
        position: Offset.zero,
      );
    });

    test('prioritizes the nearest living defense over the town hall', () {
      final target = EnemyTargetingPolicy.select(
        enemy: troll,
        playerPosition: const Offset(180, 0),
        townHall: townHall,
        buildings: [townHall, farDefense, nearDefense],
      );

      expect(target.building, same(nearDefense));
    });

    test('falls back to the town hall when all defenses are destroyed', () {
      nearDefense.health = 0;
      farDefense.health = 0;

      final target = EnemyTargetingPolicy.select(
        enemy: troll,
        playerPosition: const Offset(180, 0),
        townHall: townHall,
        buildings: [townHall, farDefense, nearDefense],
      );

      expect(target.building, same(townHall));
    });

    test('defends itself when the player enters its immediate threat area', () {
      const playerPosition = Offset(70, 0);
      final target = EnemyTargetingPolicy.select(
        enemy: troll,
        playerPosition: playerPosition,
        townHall: townHall,
        buildings: [townHall, nearDefense],
      );

      expect(target.targetsPlayer, isTrue);
      expect(target.position, playerPosition);
    });
  });

  test('target priorities let raiders choose resources before defenses', () {
    final goblin = EnemyEntity(
      id: 'goblin',
      config: EnemyConfig.goblin,
      position: Offset.zero,
    );
    final townHall = _building(
      id: 'hall',
      type: BuildingType.townHall,
      position: const Offset(400, 0),
    );
    final tower = _building(
      id: 'tower',
      type: BuildingType.watchtower,
      position: const Offset(80, 0),
    );
    final mine = _building(
      id: 'mine',
      type: BuildingType.goldMine,
      position: const Offset(260, 0),
    );

    final target = EnemyTargetingPolicy.select(
      enemy: goblin,
      playerPosition: const Offset(40, 0),
      townHall: townHall,
      buildings: [townHall, tower, mine],
    );

    expect(target.building, same(mine));
  });

  group('ranged movement', () {
    test('archer retreats when the player crosses its minimum range', () {
      final archer = EnemyEntity(
        id: 'archer',
        config: EnemyConfig.skeleton,
        position: Offset.zero,
      );
      final target = EnemyTargetSelection.player(const Offset(80, 0));

      expect(
        EnemyMovementPolicy.intentFor(enemy: archer, target: target),
        EnemyMovementIntent.retreat,
      );
    });

    test('melee units never use the ranged retreat behavior', () {
      final orc = EnemyEntity(
        id: 'orc',
        config: EnemyConfig.orc,
        position: Offset.zero,
      );
      final target = EnemyTargetSelection.player(const Offset(20, 0));

      expect(
        EnemyMovementPolicy.intentFor(enemy: orc, target: target),
        EnemyMovementIntent.advance,
      );
    });
  });

  group('squad coordination', () {
    test('nearby allies share player aggro', () {
      final alertedAlly = EnemyEntity(
        id: 'ally',
        config: EnemyConfig.orc,
        position: const Offset(100, 0),
      );
      final packMember = EnemyEntity(
        id: 'pack-member',
        config: EnemyConfig.orc,
        position: const Offset(300, 0),
      );

      expect(
        EnemyCoordinationPolicy.isPackAlerted(
          enemy: packMember,
          enemies: [alertedAlly, packMember],
          playerPosition: Offset.zero,
        ),
        isTrue,
      );
    });

    test('overlapping units receive a separation direction', () {
      final first = EnemyEntity(
        id: 'first',
        config: EnemyConfig.orc,
        position: Offset.zero,
      );
      final second = EnemyEntity(
        id: 'second',
        config: EnemyConfig.orc,
        position: const Offset(10, 0),
      );

      final separation = EnemyCoordinationPolicy.separation(
        enemy: first,
        enemies: [first, second],
      );

      expect(separation.dx, lessThan(0));
    });
  });

  test('wave difficulty grows gradually without a level 1 penalty', () {
    expect(EnemyDifficulty.healthScaleForWave(1), 1);
    expect(EnemyDifficulty.damageScaleForWave(1), 1);
    expect(EnemyDifficulty.speedScaleForWave(1), 1);
    expect(EnemyDifficulty.healthScaleForWave(5), closeTo(1.32, .001));
    expect(EnemyDifficulty.damageScaleForWave(5), closeTo(1.24, .001));
    expect(EnemyDifficulty.speedScaleForWave(5), closeTo(1.06, .001));
  });

  group('necromancer support', () {
    test('selects the most wounded nearby ally', () {
      final necromancer = EnemyEntity(
        id: 'necromancer',
        config: EnemyConfig.necromancer,
        position: Offset.zero,
      );
      final woundedOrc = EnemyEntity(
        id: 'orc',
        config: EnemyConfig.orc,
        position: const Offset(80, 0),
      )..health = 30;
      final healthierGoblin = EnemyEntity(
        id: 'goblin',
        config: EnemyConfig.goblin,
        position: const Offset(30, 0),
      )..health = 40;

      final target = EnemySupportPolicy.mostWoundedAlly(
        supporter: necromancer,
        enemies: [necromancer, healthierGoblin, woundedOrc],
        range: 200,
      );

      expect(target, same(woundedOrc));
    });

    test('ignores corpses that were already revived', () {
      final valid = _corpse(position: const Offset(100, 0), canBeRevived: true);
      final invalid = _corpse(
        position: const Offset(20, 0),
        canBeRevived: false,
      );

      final target = EnemySupportPolicy.nearestRevivableCorpse(
        origin: Offset.zero,
        corpses: [invalid, valid],
        range: 200,
      );

      expect(target, same(valid));
    });
  });
}

VillageBuildingEntity _building({
  required String id,
  required BuildingType type,
  required Offset position,
}) => VillageBuildingEntity(
  id: id,
  type: type,
  position: position,
  maxHealth: 500,
  radius: 35,
);

CorpseEntity _corpse({required Offset position, required bool canBeRevived}) =>
    CorpseEntity(
      position: position,
      sprite: EnemyConfig.goblin.sprite,
      config: EnemyConfig.goblin,
      facingLeft: false,
      isWaveEnemy: true,
      canBeRevived: canBeRevived,
    );
