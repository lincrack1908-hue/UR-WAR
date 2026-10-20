import 'package:flutter/material.dart';
import '../graphics/pixel_art_data.dart';

enum EnemyCategory {
  goblin,
  orc,
  troll,
  skeleton,
  necromancer,
  necromancerMiniboss,
  bossTitan,
}

/// High-level strategy used by the enemy AI controller.
enum EnemyBehavior { raider, siege, rangedKiter, support, miniboss }

enum EnemyAbility {
  none,
  areaStrike,
  healOrRevive,
  diamondResurrection,
  titanArsenal,
  frostStorm,
  lavaBurst,
}

/// Ordered preferences that future targeting rules can score independently.
enum TargetPriority {
  player,
  townHall,
  defenses,
  resources,
  woundedAlly,
  fallenAlly,
}

class EnemyConfig {
  final EnemyCategory category;
  final String name;
  final double maxHealth;
  final double speed;
  final double attackDamage;
  final double attackRange;
  final double attackCooldownSeconds;
  final int goldReward;
  final int scoreReward;
  final int xpReward;
  final bool isRanged;
  final bool isBoss;
  final double hitRadius;
  final PixelSpriteData sprite;
  final Color healthBarColor;
  final EnemyBehavior behavior;
  final double preferredRange;
  final double retreatRange;
  final double abilityCooldownSeconds;
  final EnemyAbility ability;
  final List<TargetPriority> targetPriorities;

  const EnemyConfig({
    required this.category,
    required this.name,
    required this.maxHealth,
    required this.speed,
    required this.attackDamage,
    required this.attackRange,
    required this.attackCooldownSeconds,
    required this.goldReward,
    required this.scoreReward,
    required this.xpReward,
    required this.isRanged,
    required this.isBoss,
    required this.hitRadius,
    required this.sprite,
    this.healthBarColor = const Color(0xFFEF233C),
    this.behavior = EnemyBehavior.raider,
    this.preferredRange = 0,
    this.retreatRange = 0,
    this.abilityCooldownSeconds = 0,
    this.ability = EnemyAbility.none,
    this.targetPriorities = const [
      TargetPriority.player,
      TargetPriority.defenses,
      TargetPriority.townHall,
    ],
  });

  static EnemyConfig get goblin => EnemyConfig(
    category: EnemyCategory.goblin,
    name: 'Goblin Saqueador',
    maxHealth: 65,
    speed: 135,
    attackDamage: 12,
    attackRange: 32,
    attackCooldownSeconds: 0.8,
    goldReward: 15,
    scoreReward: 30,
    xpReward: 15,
    isRanged: false,
    isBoss: false,
    hitRadius: 20,
    sprite: PixelArtLibrary.goblin,
    behavior: EnemyBehavior.raider,
    preferredRange: 32,
    targetPriorities: const [
      TargetPriority.resources,
      TargetPriority.defenses,
      TargetPriority.townHall,
      TargetPriority.player,
    ],
  );

  static EnemyConfig get orc => EnemyConfig(
    category: EnemyCategory.orc,
    name: 'Orco Berserker',
    maxHealth: 190,
    speed: 85,
    attackDamage: 30,
    attackRange: 40,
    attackCooldownSeconds: 1.2,
    goldReward: 35,
    scoreReward: 70,
    xpReward: 25,
    isRanged: false,
    isBoss: false,
    hitRadius: 28,
    sprite: PixelArtLibrary.orc,
    behavior: EnemyBehavior.raider,
    preferredRange: 40,
    targetPriorities: const [
      TargetPriority.player,
      TargetPriority.defenses,
      TargetPriority.townHall,
    ],
  );

  static EnemyConfig get troll => EnemyConfig(
    category: EnemyCategory.troll,
    name: 'Troll de las Cavernas',
    maxHealth: 320,
    speed: 70,
    attackDamage: 40,
    attackRange: 44,
    attackCooldownSeconds: 1.6,
    goldReward: 60,
    scoreReward: 120,
    xpReward: 40,
    isRanged: false,
    isBoss: false,
    hitRadius: 32,
    sprite: PixelArtLibrary.troll,
    healthBarColor: const Color(0xFF63B3ED),
    behavior: EnemyBehavior.siege,
    preferredRange: 44,
    abilityCooldownSeconds: 7,
    targetPriorities: const [
      TargetPriority.defenses,
      TargetPriority.townHall,
      TargetPriority.player,
    ],
  );

  static EnemyConfig get skeleton => EnemyConfig(
    category: EnemyCategory.skeleton,
    name: 'Esqueleto Arquero',
    maxHealth: 90,
    speed: 95,
    attackDamage: 18,
    attackRange: 240,
    attackCooldownSeconds: 1.5,
    goldReward: 25,
    scoreReward: 50,
    xpReward: 20,
    isRanged: true,
    isBoss: false,
    hitRadius: 22,
    sprite: PixelArtLibrary.skeleton,
    behavior: EnemyBehavior.rangedKiter,
    preferredRange: 210,
    retreatRange: 120,
    targetPriorities: const [
      TargetPriority.player,
      TargetPriority.defenses,
      TargetPriority.townHall,
    ],
  );

  static EnemyConfig get necromancer => EnemyConfig(
    category: EnemyCategory.necromancer,
    name: 'Nigromante Sombrío',
    maxHealth: 160,
    speed: 80,
    attackDamage: 28,
    attackRange: 260,
    attackCooldownSeconds: 1.8,
    goldReward: 45,
    scoreReward: 90,
    xpReward: 35,
    isRanged: true,
    isBoss: false,
    hitRadius: 24,
    sprite: PixelArtLibrary.necromancer,
    behavior: EnemyBehavior.support,
    preferredRange: 220,
    retreatRange: 140,
    abilityCooldownSeconds: 8,
    ability: EnemyAbility.healOrRevive,
    targetPriorities: const [
      TargetPriority.fallenAlly,
      TargetPriority.woundedAlly,
      TargetPriority.player,
      TargetPriority.defenses,
    ],
  );

  static EnemyConfig get necromancerMiniboss => EnemyConfig(
    category: EnemyCategory.necromancerMiniboss,
    name: 'MALACHAR, SEÑOR DE LAS TUMBAS',
    maxHealth: 620,
    speed: 68,
    attackDamage: 38,
    attackRange: 285,
    attackCooldownSeconds: 1.7,
    goldReward: 150,
    scoreReward: 380,
    xpReward: 110,
    isRanged: true,
    isBoss: true,
    hitRadius: 36,
    sprite: PixelArtLibrary.necromancer,
    healthBarColor: const Color(0xFF70E000),
    behavior: EnemyBehavior.miniboss,
    preferredRange: 240,
    retreatRange: 150,
    abilityCooldownSeconds: 10,
    ability: EnemyAbility.diamondResurrection,
    targetPriorities: const [
      TargetPriority.player,
      TargetPriority.defenses,
      TargetPriority.townHall,
    ],
  );

  static EnemyConfig get bossTitan => EnemyConfig(
    category: EnemyCategory.bossTitan,
    name: 'TITÁN DESTRUCTOR',
    maxHealth: 950,
    speed: 60,
    attackDamage: 65,
    attackRange: 60,
    attackCooldownSeconds: 1.5,
    goldReward: 200,
    scoreReward: 500,
    xpReward: 120,
    isRanged: false,
    isBoss: true,
    hitRadius: 45,
    sprite: PixelArtLibrary.bossTitan,
    healthBarColor: const Color(0xFFFF9F1C),
    behavior: EnemyBehavior.miniboss,
    preferredRange: 60,
    abilityCooldownSeconds: 6,
    ability: EnemyAbility.titanArsenal,
    targetPriorities: const [
      TargetPriority.defenses,
      TargetPriority.player,
      TargetPriority.townHall,
    ],
  );

  static EnemyConfig bossForBiome(String biome, int level) => EnemyConfig(
    category: EnemyCategory.bossTitan,
    name: biome == 'snow'
        ? 'ESPECTRO DE NIFLHEIM'
        : biome == 'lava'
        ? 'DRAGÓN INFERNUS'
        : 'TITÁN DEL VALLE',
    maxHealth: 800 + level * 150,
    speed: biome == 'snow' ? 75 : 60,
    attackDamage: 38 + level * 5,
    attackRange: 70,
    attackCooldownSeconds: 2,
    goldReward: 250,
    scoreReward: 650,
    xpReward: 240,
    isRanged: false,
    isBoss: true,
    hitRadius: 42,
    sprite: biome == 'snow'
        ? PixelArtLibrary.frostWraith
        : biome == 'lava'
        ? PixelArtLibrary.magmaDragon
        : PixelArtLibrary.bossTitan,
    healthBarColor: biome == 'snow'
        ? const Color(0xFF63DDFF)
        : const Color(0xFFFF9F1C),
    behavior: EnemyBehavior.miniboss,
    preferredRange: 70,
    abilityCooldownSeconds: 6,
    ability: biome == 'snow'
        ? EnemyAbility.frostStorm
        : biome == 'lava'
        ? EnemyAbility.lavaBurst
        : EnemyAbility.titanArsenal,
    targetPriorities: const [
      TargetPriority.defenses,
      TargetPriority.player,
      TargetPriority.townHall,
    ],
  );
}
