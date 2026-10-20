import 'package:flutter/material.dart';
import '../graphics/pixel_art_data.dart';

enum NpcRoleType {
  blacksmith, // Herrero (Mejora armas y armaduras)
  merchant, // Comerciante Isekai (Intercambia recursos / artefactos)
  questGiver, // Anciano del Gremio (Misiones y recompensas)
  guard, // Guardián Alférez (Defiende NPC y patrulla)
  alchemist, // Alquimista (Pociones y elixires mágicos)
}

class NpcQuest {
  final String id;
  final String title;
  final String description;
  final int requiredEnemyKills;
  int currentKills;
  final int goldReward;
  final int xpReward;
  bool isCompleted;
  bool isClaimed;

  NpcQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredEnemyKills,
    this.currentKills = 0,
    required this.goldReward,
    required this.xpReward,
    this.isCompleted = false,
    this.isClaimed = false,
  });
}

class NpcEntity {
  final String id;
  final String name;
  final String title;
  final NpcRoleType role;
  Offset position;
  final String dialogue;
  final PixelSpriteData sprite;
  final Color themeColor;
  NpcQuest? activeQuest;
  bool isProtected;
  double health;
  final double maxHealth;

  NpcEntity({
    required this.id,
    required this.name,
    required this.title,
    required this.role,
    required this.position,
    required this.dialogue,
    required this.sprite,
    required this.themeColor,
    this.activeQuest,
    this.isProtected = true,
    this.health = 300.0,
    this.maxHealth = 300.0,
  });
}
