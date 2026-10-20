import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/audio_engine.dart';
import 'player_class.dart';
import 'enemy_type.dart';
import '../graphics/pixel_art_data.dart';

/// Entidad controlada por el jugador con sistema RPG de niveles y habilidades
class PlayerEntity {
  Offset position;
  final PlayerClass playerClass;
  double health;
  double maxHealth;
  double attackTimer = 0.0;
  double specialSkillTimer = 0.0;
  double ultimateSkillTimer = 0.0;
  bool facingLeft = false;
  double attackAnimTimer = 0.0;
  double hitFlashTimer = 0.0;
  double walkPhase = 0.0;
  bool isMoving = false;
  Offset? targetDestination;
  Offset aimDirection = const Offset(1, 0);
  Offset moveDirection = const Offset(1, 0);
  Offset dashDirection = const Offset(1, 0);
  double dashCooldown = 0;
  double dashTimer = 0;
  double shieldTimer = 0;
  bool isBlocking = false;
  bool mageUsesIce = false;

  // Sistema de Nivel y Experiencia RPG
  int level = 1;
  int xp = 0;
  int xpToNextLevel = 300;
  int skillPoints = 0;
  final Set<String> unlockedSkillIds = {};

  // Modificadores de la tienda y pasivas
  double damageMultiplier = 1.0;
  double speedMultiplier = 1.0;
  double damageReduction = 0.0;

  int gold = 0;
  int score = 0;
  int kills = 0;

  PlayerEntity({required this.position, required this.playerClass})
    : health = playerClass.maxHealth,
      maxHealth = playerClass.maxHealth {
    level = 1;
    xp = 0;
    xpToNextLevel = xpRequirementForLevel(1);
    skillPoints = 0;
    unlockedSkillIds.add(playerClass.skillTree.first.id);
  }

  static int xpRequirementForLevel(int lvl) {
    // Curva RPG balanceada:
    // Nivel 1 -> 2: 150 XP (sobrevivir oleada 1 + primeras bajas)
    // Nivel 2 -> 3: 550 XP
    // Nivel 3 -> 4: 1200 XP
    // Nivel 4 -> 5: 2100 XP
    // Nivel 5 -> 6: 3200 XP
    if (lvl == 1) return 150;
    return 150 + (lvl - 1) * 250 + (lvl - 1) * (lvl - 1) * 150;
  }

  double get currentDamage => playerClass.baseDamage * damageMultiplier;
  double get currentSpeed => playerClass.moveSpeed * speedMultiplier;

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      skillPoints++;
      xpToNextLevel = xpRequirementForLevel(level);

      maxHealth += 20;
      health = min(maxHealth, health + maxHealth * 0.4);
      damageMultiplier += 0.08;

      AudioEngine.playLevelUp();
    }
  }

  void takeDamage(double amount) {
    if (dashTimer > 0 || shieldTimer > 0) return;
    final effectiveDamage = amount * (1.0 - damageReduction).clamp(0.1, 1.0);
    health = max(0, health - effectiveDamage);
    hitFlashTimer = 0.25;
  }

  void heal(double amount) {
    health = min(maxHealth, health + amount);
  }
}

/// Campamento / Bastión Rival enemigo en la naturaleza
class RivalCampEntity {
  final String id;
  final String name;
  final Offset position;
  double health;
  double maxHealth;
  final int goldReward;
  final int xpReward;
  double spawnTimer = 0.0;
  double hitFlashTimer = 0.0;
  final double radius;

  RivalCampEntity({
    required this.id,
    required this.name,
    required this.position,
    this.maxHealth = 450,
    this.goldReward = 350,
    this.xpReward = 400,
    this.radius = 45,
  }) : health = maxHealth;

  bool get isDestroyed => health <= 0;

  void takeDamage(double amount) {
    health = max(0, health - amount);
    hitFlashTimer = 0.25;
  }
}

/// Nodo de recurso recolectable (Mina de oro, Cristales de maná)
class ResourceNodeEntity {
  final String id;
  final String type; // 'gold_mine', 'mana_crystal'
  final Offset position;
  int resourcesRemaining;
  double harvestTimer = 0.0;

  ResourceNodeEntity({
    required this.id,
    required this.type,
    required this.position,
    this.resourcesRemaining = 250,
  });

  bool get isDepleted => resourcesRemaining <= 0;
}

/// Entidad de invasor enemigo
class EnemyEntity {
  final String id;
  final EnemyConfig config;
  Offset position;
  double health;
  final double maxHealth;
  final double damageScale;
  final double speedScale;
  bool facingLeft = false;
  double attackTimer = 0.0;
  double hitFlashTimer = 0.0;
  double walkPhase = 0.0;

  double slowTimer = 0;
  double slowFactor = 1;
  double abilityTimer = 3;
  int phase = 1;
  bool rewardGranted = false;
  bool isWaveEnemy;
  final bool canBeRevived;
  final bool grantsReward;
  final String? guardLeaderId;
  final Offset guardOffset;
  double emergenceTimer;
  double vulnerableTimer = 0;
  int abilityCastCount = 0;

  EnemyEntity({
    required this.id,
    required this.config,
    required this.position,
    this.isWaveEnemy = false,
    this.canBeRevived = true,
    this.grantsReward = true,
    this.guardLeaderId,
    this.guardOffset = Offset.zero,
    this.emergenceTimer = 0,
    double healthScale = 1,
    this.damageScale = 1,
    this.speedScale = 1,
  }) : maxHealth = config.maxHealth * healthScale,
       health = config.maxHealth * healthScale;

  bool get isDead => health <= 0;
  double get attackDamage => config.attackDamage * damageScale;
  double get movementSpeed => config.speed * speedScale;

  void takeDamage(double amount) {
    health = max(0, health - amount);
    hitFlashTimer = 0.2;
  }
}

/// Heavy ground projectile used by titan-type bosses.
class RollingRockEntity {
  Offset position;
  final Offset velocity;
  final double damage;
  final double radius;
  double lifeTime;
  double rotation = 0;

  RollingRockEntity({
    required this.position,
    required this.velocity,
    required this.damage,
    this.radius = 20,
    this.lifeTime = 4.5,
  });

  bool get isExpired => lifeTime <= 0;
}

enum BuildingType {
  townHall,
  watchtower,
  cottage,
  barricade,
  goldMine,
  frostTower,
  cannonTower,
}

/// Edificio perteneciente a la aldea que debe ser defendido o construido
class VillageBuildingEntity {
  final String id;
  final BuildingType type;
  final Offset position;
  double health;
  double maxHealth;
  int level = 1;
  double shootTimer = 0.0;
  double goldGenerationTimer = 0.0;
  double hitFlashTimer = 0.0;
  final double radius;

  VillageBuildingEntity({
    required this.id,
    required this.type,
    required this.position,
    required this.maxHealth,
    required this.radius,
  }) : health = maxHealth;

  int get upgradeCost => 75 * level;
  int get repairCost => ((maxHealth - health) * 0.12).ceil();
  bool get isDead => health <= 0;

  void takeDamage(double amount) {
    health = max(0, health - amount);
    hitFlashTimer = 0.2;
  }

  void repair(double amount) {
    health = min(maxHealth, health + amount);
  }
}

/// Proyectiles disparados por héroes, torres o enemigos
class ProjectileEntity {
  Offset position;
  final Offset velocity;
  final double damage;
  final double radius;
  final Color color;
  final bool isFromPlayer;
  final bool isExplosive;
  final double explosionRadius;
  double lifeTime;
  int pierceCount;
  final Set<String> hitTargetIds = {};
  final double slowDuration;
  final double slowFactor;

  ProjectileEntity({
    required this.position,
    required this.velocity,
    required this.damage,
    this.radius = 4.0,
    required this.color,
    required this.isFromPlayer,
    this.isExplosive = false,
    this.explosionRadius = 0.0,
    this.lifeTime = 2.0,
    this.pierceCount = 1,
    this.slowDuration = 0,
    this.slowFactor = 0.5,
  });

  bool get isExpired => lifeTime <= 0;
}

/// Textos flotantes para daño, curaciones y alertas
class FloatingTextEntity {
  Offset position;
  final String text;
  final Color color;
  final double fontSize;
  double lifeTime;
  final double maxLifeTime;

  FloatingTextEntity({
    required this.position,
    required this.text,
    required this.color,
    this.fontSize = 14.0,
    this.lifeTime = 1.0,
  }) : maxLifeTime = lifeTime;

  double get opacity => max(0.0, min(1.0, lifeTime / maxLifeTime));
  bool get isExpired => lifeTime <= 0;
}

/// Partículas visuales para sangre, chispas, polvo o magia
class ParticleEntity {
  Offset position;
  Offset velocity;
  final Color color;
  double radius;
  double lifeTime;
  final double maxLifeTime;

  ParticleEntity({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.lifeTime,
  }) : maxLifeTime = lifeTime;

  double get opacity => max(0.0, min(1.0, lifeTime / maxLifeTime));
  bool get isExpired => lifeTime <= 0;
}

/// Shared prices and combat values for construction previews and the shop.
class BuildingSpec {
  final String name;
  final int cost;
  final double maxHealth, radius, damage, range, cooldown;
  const BuildingSpec(
    this.name,
    this.cost,
    this.maxHealth,
    this.radius, {
    this.damage = 0,
    this.range = 0,
    this.cooldown = 1,
  });

  static BuildingSpec forType(BuildingType type) => switch (type) {
    BuildingType.townHall => const BuildingSpec('Salón comunal', 0, 1200, 50),
    BuildingType.watchtower => const BuildingSpec(
      'Torre de flechas',
      100,
      500,
      35,
      damage: 35,
      range: 320,
      cooldown: 0.9,
    ),
    BuildingType.frostTower => const BuildingSpec(
      'Torre de escarcha',
      160,
      400,
      32,
      damage: 16,
      range: 300,
      cooldown: 1.1,
    ),
    BuildingType.cannonTower => const BuildingSpec(
      'Torre de asedio',
      220,
      550,
      36,
      damage: 65,
      range: 340,
      cooldown: 2.2,
    ),
    BuildingType.barricade => const BuildingSpec('Barricada', 50, 650, 28),
    BuildingType.goldMine => const BuildingSpec('Mina de oro', 150, 350, 32),
    BuildingType.cottage => const BuildingSpec('Cabaña', 80, 350, 35),
  };
}

/// A telegraphed attack, trap or persistent sanctuary, shared with the renderer.
class HazardEntity {
  final Offset position;
  final double radius, damage;
  final Color color;
  final bool isFriendly;
  final String type;
  double delay, duration;
  final double initialDelay;
  final double initialDuration;
  double tickTimer = 0;
  bool triggered = false;
  HazardEntity({
    required this.position,
    required this.radius,
    required this.damage,
    required this.color,
    this.isFriendly = false,
    this.type = 'impact',
    this.delay = 1.2,
    this.duration = 0.35,
  }) : initialDelay = delay,
       initialDuration = duration;
  bool get isWarning => delay > 0;
  bool get isActive => delay <= 0 && duration > 0;
  double get warningProgress =>
      initialDelay <= 0 ? 1 : (1 - delay / initialDelay).clamp(0, 1);
  double get activeProgress =>
      initialDuration <= 0 ? 1 : (1 - duration / initialDuration).clamp(0, 1);
}

class CorpseEntity {
  final Offset position;
  final PixelSpriteData sprite;
  final EnemyConfig config;
  final bool facingLeft;
  final bool isWaveEnemy;
  final bool canBeRevived;
  final double healthScale;
  final double damageScale;
  final double speedScale;
  double lifeTime;
  final double maxLifeTime;
  double reviveWindow;
  CorpseEntity({
    required this.position,
    required this.sprite,
    required this.config,
    required this.facingLeft,
    required this.isWaveEnemy,
    required this.canBeRevived,
    this.healthScale = 1,
    this.damageScale = 1,
    this.speedScale = 1,
    this.lifeTime = 0.65,
    this.reviveWindow = 6.0,
  }) : maxLifeTime = lifeTime;
}
