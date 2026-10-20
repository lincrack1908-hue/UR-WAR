import 'package:flutter/material.dart';
import '../graphics/pixel_art_data.dart';

enum PlayerRoleType { knight, ranger, mage, cleric }

class HeroSkill {
  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final IconData icon;
  final double cooldownSeconds;
  final bool isPassive;
  final bool isUltimate;

  const HeroSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.icon,
    required this.cooldownSeconds,
    this.isPassive = false,
    this.isUltimate = false,
  });
}

class PlayerClass {
  final PlayerRoleType type;
  final String name;
  final String roleTitle;
  final String description;
  final double maxHealth;
  final double moveSpeed;
  final double baseDamage;
  final double attackRange;
  final double attackCooldownSeconds;
  final String specialSkillName;
  final String specialSkillDescription;
  final double specialSkillCooldownSeconds;
  final bool isMelee;
  final Color themeColor;
  final PixelSpriteData spriteIdle;
  final PixelSpriteData spriteAttack;
  final String weaponName;
  final List<HeroSkill> skillTree;

  const PlayerClass({
    required this.type,
    required this.name,
    required this.roleTitle,
    required this.description,
    required this.maxHealth,
    required this.moveSpeed,
    required this.baseDamage,
    required this.attackRange,
    required this.attackCooldownSeconds,
    required this.specialSkillName,
    required this.specialSkillDescription,
    required this.specialSkillCooldownSeconds,
    required this.isMelee,
    required this.themeColor,
    required this.spriteIdle,
    required this.spriteAttack,
    required this.weaponName,
    required this.skillTree,
  });

  static final List<PlayerClass> availableClasses = [
    PlayerClass(
      type: PlayerRoleType.knight,
      name: 'Caballero Imperial',
      roleTitle: 'Tanque & Asalto Cuerpo a Cuerpo',
      description:
          'Armado con armadura de acero y mandoble forjado. Alta resistencia y daño frontal en abanico.',
      maxHealth: 300,
      moveSpeed: 175,
      baseDamage: 45,
      attackRange: 80,
      attackCooldownSeconds: 0.45,
      specialSkillName: 'Torbellino de Acero',
      specialSkillDescription:
          'Gira a 360° causando 120 de daño y repeliendo a todos los invasores cercanos.',
      specialSkillCooldownSeconds: 6.0,
      isMelee: true,
      themeColor: const Color(0xFFAB645B),
      spriteIdle: PixelArtLibrary.knightIdle,
      spriteAttack: PixelArtLibrary.knightAttack,
      weaponName: 'Mandoble de Acero',
      skillTree: const [
        HeroSkill(
          id: 'k_active_1',
          name: 'Torbellino de Acero',
          description: 'Corta a 360° repeliendo enemigos.',
          requiredLevel: 1,
          icon: Icons.sync_rounded,
          cooldownSeconds: 6.0,
        ),
        HeroSkill(
          id: 'k_passive_1',
          name: 'Coraza Impenetrable',
          description: 'Pasiva: Reduce un 25% todo el daño recibido.',
          requiredLevel: 3,
          icon: Icons.shield_rounded,
          cooldownSeconds: 0.0,
          isPassive: true,
        ),
        HeroSkill(
          id: 'k_ultimate',
          name: 'Impacto Sísmico',
          description:
              'Definitiva: Terremoto que aturde y daña a todos los enemigos en 200px.',
          requiredLevel: 5,
          icon: Icons.electric_bolt_rounded,
          cooldownSeconds: 12.0,
          isUltimate: true,
        ),
      ],
    ),
    PlayerClass(
      type: PlayerRoleType.ranger,
      name: 'Cazadora Silvana',
      roleTitle: 'Tiradora Ágil a Distancia',
      description:
          'Gran agilidad y disparos de largo alcance. Mantiene a las hordas a raya antes de que alcancen la aldea.',
      maxHealth: 170,
      moveSpeed: 230,
      baseDamage: 32,
      attackRange: 320,
      attackCooldownSeconds: 0.35,
      specialSkillName: 'Lluvia de Flechas',
      specialSkillDescription:
          'Dispara una ráfaga masiva en abanico de 9 flechas perforantes simultáneas.',
      specialSkillCooldownSeconds: 5.0,
      isMelee: false,
      themeColor: const Color(0xFF7E9C6F),
      spriteIdle: PixelArtLibrary.rangerIdle,
      spriteAttack: PixelArtLibrary.rangerAttack,
      weaponName: 'Arco Compuesto Élfico',
      skillTree: const [
        HeroSkill(
          id: 'r_active_1',
          name: 'Lluvia de Flechas',
          description: 'Ráfaga de 9 flechas perforantes.',
          requiredLevel: 1,
          icon: Icons.grain_rounded,
          cooldownSeconds: 5.0,
        ),
        HeroSkill(
          id: 'r_passive_1',
          name: 'Ojo de Águila',
          description: 'Pasiva: Aumenta la velocidad de ataque un 30%.',
          requiredLevel: 3,
          icon: Icons.visibility_rounded,
          cooldownSeconds: 0.0,
          isPassive: true,
        ),
        HeroSkill(
          id: 'r_ultimate',
          name: 'Flecha del Dragón',
          description:
              'Definitiva: Proyectil gigante incandescente que atraviesa todo el mapa.',
          requiredLevel: 5,
          icon: Icons.local_fire_department_rounded,
          cooldownSeconds: 10.0,
          isUltimate: true,
        ),
      ],
    ),
    PlayerClass(
      type: PlayerRoleType.mage,
      name: 'Mago Arcano',
      roleTitle: 'Destrucción de Área & Magia Elemental',
      description:
          'Canaliza energía mágica en esferas ígneas explosivas que aniquilan grupos densos de enemigos.',
      maxHealth: 140,
      moveSpeed: 185,
      baseDamage: 55,
      attackRange: 290,
      attackCooldownSeconds: 0.55,
      specialSkillName: 'Meteoro Cataclísmico',
      specialSkillDescription:
          'Detona una gigantesca supernova arcana que arrasa a todos los monstruos en un radio de 180px.',
      specialSkillCooldownSeconds: 7.5,
      isMelee: false,
      themeColor: const Color(0xFF9982A7),
      spriteIdle: PixelArtLibrary.mageIdle,
      spriteAttack: PixelArtLibrary.mageIdle,
      weaponName: 'Báculo de Fuego Astral',
      skillTree: const [
        HeroSkill(
          id: 'm_active_1',
          name: 'Meteoro Cataclísmico',
          description: 'Explosión arcana masiva en área.',
          requiredLevel: 1,
          icon: Icons.auto_awesome_rounded,
          cooldownSeconds: 7.5,
        ),
        HeroSkill(
          id: 'm_passive_1',
          name: 'Sifón de Maná',
          description: 'Pasiva: Restaura 15 HP al matar enemigos con magia.',
          requiredLevel: 3,
          icon: Icons.local_pharmacy_rounded,
          cooldownSeconds: 0.0,
          isPassive: true,
        ),
        HeroSkill(
          id: 'm_ultimate',
          name: 'Tormenta de Escarcha',
          description:
              'Definitiva: Congela y ralentiza un 80% a todos los enemigos durante 6s.',
          requiredLevel: 5,
          icon: Icons.ac_unit_rounded,
          cooldownSeconds: 14.0,
          isUltimate: true,
        ),
      ],
    ),
    PlayerClass(
      type: PlayerRoleType.cleric,
      name: 'Guardiana Sagrada',
      roleTitle: 'Soporte, Fortificación & Sanación',
      description:
          'Protectora devota con bastón consagrado. Capaz de curar sus propias heridas y reparar el Gran Salón de la Aldea.',
      maxHealth: 250,
      moveSpeed: 190,
      baseDamage: 40,
      attackRange: 90,
      attackCooldownSeconds: 0.50,
      specialSkillName: 'Bendición Protectora',
      specialSkillDescription:
          'Cura 90 HP al héroe y restaura instantáneamente 250 HP a la estructura de la Aldea.',
      specialSkillCooldownSeconds: 9.0,
      isMelee: true,
      themeColor: const Color(0xFFD4BC80),
      spriteIdle: PixelArtLibrary.clericIdle,
      spriteAttack: PixelArtLibrary.clericIdle,
      weaponName: 'Martillo Rúnico Divino',
      skillTree: const [
        HeroSkill(
          id: 'c_active_1',
          name: 'Bendición Protectora',
          description: 'Cura al héroe y repara el Salón Comunal.',
          requiredLevel: 1,
          icon: Icons.favorite_rounded,
          cooldownSeconds: 9.0,
        ),
        HeroSkill(
          id: 'c_passive_1',
          name: 'Aura Celestial',
          description:
              'Pasiva: Regenera 5 HP por segundo a todas las torres aliadas.',
          requiredLevel: 3,
          icon: Icons.wb_sunny_rounded,
          cooldownSeconds: 0.0,
          isPassive: true,
        ),
        HeroSkill(
          id: 'c_ultimate',
          name: 'Escudo Divino',
          description:
              'Definitiva: Otorga invulnerabilidad total a la aldea durante 6 segundos.',
          requiredLevel: 5,
          icon: Icons.security_rounded,
          cooldownSeconds: 15.0,
          isUltimate: true,
        ),
      ],
    ),
  ];
}
