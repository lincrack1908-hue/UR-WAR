import 'package:flutter_test/flutter_test.dart';
import 'package:ur_war/game/models/enemy_type.dart';
import 'package:ur_war/game/models/game_map.dart';
import 'package:ur_war/game/models/wave_system.dart';

void main() {
  group('Troll de las Cavernas', () {
    test('tiene estadísticas de enemigo pesado cuerpo a cuerpo', () {
      final troll = EnemyConfig.troll;
      expect(troll.category, EnemyCategory.troll);
      expect(troll.isBoss, isFalse);
      expect(troll.isRanged, isFalse);
      expect(troll.maxHealth, greaterThan(EnemyConfig.orc.maxHealth));
      expect(troll.goldReward, greaterThan(EnemyConfig.orc.goldReward));
    });

    test('no aparece en las primeras oleadas', () {
      final waves = WaveSystem(maxWaves: 5, biome: MapBiomeType.forest);
      waves.startWave(2, 1000, 1000);
      expect(waves.nextWaveSummary.contains('Troll'), isFalse);
    });

    test('aparece desde la oleada 3', () {
      final waves = WaveSystem(maxWaves: 5, biome: MapBiomeType.forest);
      waves.startWave(3, 1000, 1000);
      expect(waves.nextWaveSummary.contains('Troll de las Cavernas'), isTrue);
    });
  });

  group('Malachar miniboss', () {
    test('appears in wave 4 of level 1 before the final boss', () {
      final waves = WaveSystem(
        maxWaves: 5,
        biome: MapBiomeType.forest,
        level: 1,
      );

      waves.startWave(4, 1000, 1000);

      expect(
        waves.nextWaveSummary,
        contains(EnemyConfig.necromancerMiniboss.name),
      );
    });

    test('does not replace the final biome boss', () {
      final waves = WaveSystem(
        maxWaves: 5,
        biome: MapBiomeType.forest,
        level: 1,
      );

      waves.startWave(5, 1000, 1000);

      expect(waves.nextWaveSummary, contains('TITÁN DEL VALLE'));
      expect(
        waves.nextWaveSummary,
        isNot(contains(EnemyConfig.necromancerMiniboss.name)),
      );
    });
  });
}
