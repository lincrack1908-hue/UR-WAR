import 'dart:math';
import 'package:flutter/material.dart';
import '../models/enemy_type.dart';
import '../models/entity.dart';

/// Immutable result of an AI targeting decision.
///
/// Keeping target selection separate from movement and attacks lets each
/// behavior evolve without duplicating combat code.
class EnemyTargetSelection {
  final Offset position;
  final bool targetsPlayer;
  final VillageBuildingEntity? building;

  EnemyTargetSelection.player(this.position)
    : targetsPlayer = true,
      building = null;

  EnemyTargetSelection.building(VillageBuildingEntity target)
    : position = target.position,
      targetsPlayer = false,
      building = target;

  double distanceFrom(Offset origin) => (position - origin).distance;
}

/// Selects combat targets according to the strategy declared by each enemy.
///
/// Siege units remain focused on structures unless the player enters their
/// immediate threat radius. Other roles retain the original proximity-based
/// targeting until their dedicated behavior phase is implemented.
class EnemyTargetingPolicy {
  static const double defaultPlayerAggroRange = 180;
  static const double siegePlayerThreatRange = 90;

  static EnemyTargetSelection select({
    required EnemyEntity enemy,
    required Offset playerPosition,
    required VillageBuildingEntity townHall,
    required Iterable<VillageBuildingEntity> buildings,
  }) {
    if (enemy.config.behavior == EnemyBehavior.siege) {
      return _selectSiegeTarget(
        enemy: enemy,
        playerPosition: playerPosition,
        townHall: townHall,
        buildings: buildings,
      );
    }

    return _selectByPriority(
      enemy: enemy,
      playerPosition: playerPosition,
      townHall: townHall,
      buildings: buildings,
    );
  }

  static EnemyTargetSelection _selectByPriority({
    required EnemyEntity enemy,
    required Offset playerPosition,
    required VillageBuildingEntity townHall,
    required Iterable<VillageBuildingEntity> buildings,
  }) {
    final playerIsRelevant =
        (playerPosition - enemy.position).distance < defaultPlayerAggroRange;
    for (final priority in enemy.config.targetPriorities) {
      if (priority == TargetPriority.player && playerIsRelevant) {
        return EnemyTargetSelection.player(playerPosition);
      }
      final target = _nearest(
        enemy.position,
        buildings.where(
          (building) => !building.isDead && _matches(priority, building.type),
        ),
      );
      if (target != null) return EnemyTargetSelection.building(target);
    }

    if (playerIsRelevant) return EnemyTargetSelection.player(playerPosition);
    return EnemyTargetSelection.building(
      _nearestLivingBuilding(enemy.position, buildings, townHall),
    );
  }

  static EnemyTargetSelection _selectSiegeTarget({
    required EnemyEntity enemy,
    required Offset playerPosition,
    required VillageBuildingEntity townHall,
    required Iterable<VillageBuildingEntity> buildings,
  }) {
    if ((playerPosition - enemy.position).distance < siegePlayerThreatRange) {
      return EnemyTargetSelection.player(playerPosition);
    }

    for (final priority in enemy.config.targetPriorities) {
      final candidates = buildings.where(
        (building) => !building.isDead && _matches(priority, building.type),
      );
      final target = _nearest(enemy.position, candidates);
      if (target != null) return EnemyTargetSelection.building(target);

      if (priority == TargetPriority.player) {
        return EnemyTargetSelection.player(playerPosition);
      }
    }

    return EnemyTargetSelection.building(
      _nearestLivingBuilding(enemy.position, buildings, townHall),
    );
  }

  static bool _matches(TargetPriority priority, BuildingType type) {
    return switch (priority) {
      TargetPriority.townHall => type == BuildingType.townHall,
      TargetPriority.defenses => switch (type) {
        BuildingType.watchtower ||
        BuildingType.barricade ||
        BuildingType.frostTower ||
        BuildingType.cannonTower => true,
        _ => false,
      },
      TargetPriority.resources => type == BuildingType.goldMine,
      _ => false,
    };
  }

  static VillageBuildingEntity _nearestLivingBuilding(
    Offset origin,
    Iterable<VillageBuildingEntity> buildings,
    VillageBuildingEntity fallback,
  ) =>
      _nearest(origin, buildings.where((building) => !building.isDead)) ??
      fallback;

  static VillageBuildingEntity? _nearest(
    Offset origin,
    Iterable<VillageBuildingEntity> candidates,
  ) {
    VillageBuildingEntity? nearest;
    var nearestDistance = double.infinity;
    for (final candidate in candidates) {
      final distance = (candidate.position - origin).distanceSquared;
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }
}

enum EnemyMovementIntent { advance, retreat }

/// Decides when ranged enemies must create space before firing again.
class EnemyMovementPolicy {
  static EnemyMovementIntent intentFor({
    required EnemyEntity enemy,
    required EnemyTargetSelection target,
  }) {
    final keepsDistance =
        enemy.config.behavior == EnemyBehavior.rangedKiter ||
        enemy.config.behavior == EnemyBehavior.support;
    final distance = target.distanceFrom(enemy.position);
    if (keepsDistance &&
        target.targetsPlayer &&
        distance < enemy.config.retreatRange) {
      return EnemyMovementIntent.retreat;
    }
    return EnemyMovementIntent.advance;
  }
}

class EnemyDifficulty {
  static double healthScaleForWave(int wave) =>
      1 + (wave - 1).clamp(0, 8) * 0.08;
  static double damageScaleForWave(int wave) =>
      1 + (wave - 1).clamp(0, 8) * 0.06;
  static double speedScaleForWave(int wave) =>
      1 + (wave - 1).clamp(0, 8) * 0.015;
}

/// Lightweight squad coordination: nearby enemies share aggro, melee raiders
/// choose different approach angles, and moving groups keep personal space.
class EnemyCoordinationPolicy {
  static bool isPackAlerted({
    required EnemyEntity enemy,
    required Iterable<EnemyEntity> enemies,
    required Offset playerPosition,
  }) {
    if (enemy.config.behavior != EnemyBehavior.raider &&
        enemy.config.behavior != EnemyBehavior.rangedKiter) {
      return false;
    }
    for (final ally in enemies) {
      if (ally.isDead || identical(ally, enemy)) continue;
      if ((ally.position - enemy.position).distance > 240) continue;
      if ((playerPosition - ally.position).distance <= 180) return true;
    }
    return false;
  }

  static Offset flankOffset(String enemyId, {double radius = 44}) {
    final seed = enemyId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final angle = (seed % 6) * pi / 3;
    return Offset(cos(angle), sin(angle)) * radius;
  }

  static Offset separation({
    required EnemyEntity enemy,
    required Iterable<EnemyEntity> enemies,
    double radius = 52,
  }) {
    var result = Offset.zero;
    for (final other in enemies) {
      if (other.isDead || identical(other, enemy)) continue;
      final away = enemy.position - other.position;
      final distance = away.distance;
      if (distance <= 0 || distance >= radius) continue;
      result += away / distance * (1 - distance / radius);
    }
    return result.distance > 0 ? result / result.distance : Offset.zero;
  }
}

/// Finds valid support targets without coupling the decision to rendering or
/// movement code.
class EnemySupportPolicy {
  static EnemyEntity? mostWoundedAlly({
    required EnemyEntity supporter,
    required Iterable<EnemyEntity> enemies,
    required double range,
  }) {
    EnemyEntity? target;
    var lowestHealthRatio = 0.75;
    for (final ally in enemies) {
      if (identical(ally, supporter) || ally.isDead) continue;
      if ((ally.position - supporter.position).distance > range) continue;
      final healthRatio = ally.health / ally.maxHealth;
      if (healthRatio < lowestHealthRatio) {
        lowestHealthRatio = healthRatio;
        target = ally;
      }
    }
    return target;
  }

  static CorpseEntity? nearestRevivableCorpse({
    required Offset origin,
    required Iterable<CorpseEntity> corpses,
    required double range,
  }) {
    CorpseEntity? target;
    var nearestDistance = range;
    for (final corpse in corpses) {
      final validCategory =
          !corpse.config.isBoss &&
          corpse.config.behavior != EnemyBehavior.support;
      if (!corpse.canBeRevived || corpse.reviveWindow <= 0 || !validCategory) {
        continue;
      }
      final distance = (corpse.position - origin).distance;
      if (distance <= nearestDistance) {
        nearestDistance = distance;
        target = corpse;
      }
    }
    return target;
  }
}
