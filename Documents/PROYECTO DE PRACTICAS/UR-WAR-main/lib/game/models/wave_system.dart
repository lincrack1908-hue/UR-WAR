import 'dart:math';
import 'package:flutter/material.dart';
import 'enemy_type.dart';
import 'game_map.dart';

class WaveSpawnEntry {
  final EnemyConfig config;
  final double delaySeconds;
  final int spawnEdge;
  const WaveSpawnEntry({
    required this.config,
    required this.delaySeconds,
    required this.spawnEdge,
  });
}

class WaveSystem {
  int currentWave = 1;
  final int maxWaves;
  final MapBiomeType biome;
  final int level;
  bool isWaveInProgress = false;
  double waveTimer = 0;
  double intermissionTimer = 0;
  final List<WaveSpawnEntry> _pendingSpawns = [];
  final Random _random = Random(42);
  int totalEnemiesInCurrentWave = 0;
  int enemiesSpawnedSoFar = 0;

  WaveSystem({
    this.maxWaves = 5,
    this.biome = MapBiomeType.forest,
    this.level = 1,
  });

  String get nextWaveSummary {
    final roster = _roster(currentWave);
    final counts = <String, int>{};
    for (final enemy in roster) {
      counts.update(enemy.name, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts.entries.map((e) => '${e.value} ${e.key}').join(' · ');
  }

  void startIntermission([double duration = 0]) {
    isWaveInProgress = false;
    intermissionTimer = 0; // Preparation ends only when the player is ready.
    _pendingSpawns.clear();
  }

  List<EnemyConfig> _roster(int wave) {
    final roster = <EnemyConfig>[];
    final basic = biome == MapBiomeType.snow
        ? EnemyConfig.skeleton
        : EnemyConfig.goblin;
    roster.addAll(List.generate(5 + wave * 2, (_) => basic));
    if (wave >= 2) {
      roster.addAll(List.generate(1 + wave ~/ 2, (_) => EnemyConfig.orc));
    }
    if (wave >= 3) {
      roster.addAll(
        List.generate(1 + (wave - 3) ~/ 2, (_) => EnemyConfig.troll),
      );
    }
    if (wave >= 3 && biome != MapBiomeType.snow) {
      roster.addAll(List.generate(wave ~/ 2, (_) => EnemyConfig.skeleton));
    }
    if (wave >= 4 || biome == MapBiomeType.lava) {
      roster.addAll(
        List.generate(max(1, wave ~/ 3), (_) => EnemyConfig.necromancer),
      );
    }
    if (level == 1 && wave == max(3, maxWaves - 1)) {
      roster.insert(0, EnemyConfig.necromancerMiniboss);
    }
    if (wave == maxWaves) {
      roster.insert(0, EnemyConfig.bossForBiome(biome.name, level));
    }
    return roster;
  }

  void startWave(int waveNumber, double worldWidth, double worldHeight) {
    if (waveNumber < 1 || waveNumber > maxWaves) return;
    currentWave = waveNumber;
    isWaveInProgress = true;
    intermissionTimer = 0;
    waveTimer = 0;
    _pendingSpawns.clear();
    enemiesSpawnedSoFar = 0;
    final roster = _roster(waveNumber);
    for (var i = 0; i < roster.length; i++) {
      _pendingSpawns.add(
        WaveSpawnEntry(
          config: roster[i],
          delaySeconds: i * max(0.55, 1.15 - waveNumber * 0.06),
          spawnEdge: (waveNumber + i % 2) % 4,
        ),
      );
    }
    totalEnemiesInCurrentWave = roster.length;
  }

  List<MapEntry<EnemyConfig, Offset>> update(
    double dt,
    double worldWidth,
    double worldHeight,
  ) {
    if (!isWaveInProgress) return [];
    waveTimer += dt;
    final readySpawns = <MapEntry<EnemyConfig, Offset>>[];
    while (_pendingSpawns.isNotEmpty &&
        _pendingSpawns.first.delaySeconds <= waveTimer) {
      final entry = _pendingSpawns.removeAt(0);
      enemiesSpawnedSoFar++;
      const margin = 55.0;
      final spread = (_random.nextDouble() - 0.5) * 180;
      final pos = switch (entry.spawnEdge) {
        0 => Offset(worldWidth / 2 + spread, margin),
        1 => Offset(worldWidth - margin, worldHeight / 2 + spread),
        2 => Offset(worldWidth / 2 + spread, worldHeight - margin),
        _ => Offset(margin, worldHeight / 2 + spread),
      };
      readySpawns.add(MapEntry(entry.config, pos));
    }
    return readySpawns;
  }

  bool get hasCompletedAllSpawns => _pendingSpawns.isEmpty;
}
