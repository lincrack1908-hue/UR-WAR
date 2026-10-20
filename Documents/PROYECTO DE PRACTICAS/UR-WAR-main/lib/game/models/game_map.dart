import 'package:flutter/material.dart';

enum MapBiomeType { forest, snow, lava }

class MapObstacle {
  final Offset position;
  final double radius;
  final String type; // 'tree', 'rock', 'water', 'bonfire'

  const MapObstacle({
    required this.position,
    required this.radius,
    required this.type,
  });
}

class RivalCampConfig {
  final String name;
  final Offset position;
  final int level;

  const RivalCampConfig({
    required this.name,
    required this.position,
    required this.level,
  });
}

class GameMapModel {
  final String id;
  final int levelIndex;
  final String name;
  final String subtitle;
  final String difficultyText;
  final String description;
  final MapBiomeType biome;
  final double worldWidth;
  final double worldHeight;
  final Color groundColor;
  final Color groundAccentColor;
  final Color pathColor;
  final Color wallColor;
  final int totalWaves;
  final List<MapObstacle> obstacles;
  final List<RivalCampConfig> rivalCamps;

  const GameMapModel({
    required this.id,
    required this.levelIndex,
    required this.name,
    required this.subtitle,
    required this.difficultyText,
    required this.description,
    required this.biome,
    required this.worldWidth,
    required this.worldHeight,
    required this.groundColor,
    required this.groundAccentColor,
    required this.pathColor,
    required this.wallColor,
    required this.totalWaves,
    required this.obstacles,
    required this.rivalCamps,
  });

  static List<GameMapModel> get availableMaps => [
    GameMapModel(
      id: 'level_1_forest',
      levelIndex: 1,
      name: 'Nivel 1: Reinos del Valle Esmeralda',
      subtitle: 'Gran Bosque del Continente Isekai',
      difficultyText: 'Fácil (Iniciación)',
      description:
          'Un vasto territorio con aldeas de colonos, puestos de avanzada goblins, comerciantes ambulantes y ruinas antiguas.',
      biome: MapBiomeType.forest,
      worldWidth: 4200,
      worldHeight: 3400,
      groundColor: const Color(0xFF303A2E),
      groundAccentColor: const Color(0xFF535D43),
      pathColor: const Color(0xFF5E503F),
      wallColor: const Color(0xFF7F4F24),
      totalWaves: 5,
      obstacles: [
        const MapObstacle(position: Offset(450, 450), radius: 48, type: 'tree'),
        const MapObstacle(
          position: Offset(3650, 460),
          radius: 48,
          type: 'tree',
        ),
        const MapObstacle(
          position: Offset(460, 2850),
          radius: 48,
          type: 'tree',
        ),
        const MapObstacle(
          position: Offset(3640, 2860),
          radius: 48,
          type: 'tree',
        ),
        const MapObstacle(
          position: Offset(1200, 800),
          radius: 36,
          type: 'rock',
        ),
        const MapObstacle(
          position: Offset(2800, 2200),
          radius: 40,
          type: 'tree',
        ),
      ],
      rivalCamps: [
        const RivalCampConfig(
          name: 'Campamento Goblin del Norte',
          position: Offset(2100, 400),
          level: 1,
        ),
        const RivalCampConfig(
          name: 'Guarida Salvaje del Sur',
          position: Offset(2100, 2900),
          level: 1,
        ),
        const RivalCampConfig(
          name: 'Fortaleza Bandida del Oeste',
          position: Offset(500, 1700),
          level: 2,
        ),
        const RivalCampConfig(
          name: 'Enclave Orco del Este',
          position: Offset(3700, 1700),
          level: 2,
        ),
      ],
    ),
    GameMapModel(
      id: 'level_2_orcs',
      levelIndex: 2,
      name: 'Nivel 2: Asedio Fronterizo de los Titanes',
      subtitle: 'Dominio Tribal de las Hordas',
      difficultyText: 'Normal',
      description:
          'Mapeado colosal con múltiples fortalezas rivales, gremios de herreros y campos de entrenamiento militar.',
      biome: MapBiomeType.forest,
      worldWidth: 4600,
      worldHeight: 3600,
      groundColor: const Color(0xFF363C2C),
      groundAccentColor: const Color(0xFF616349),
      pathColor: const Color(0xFF6B5844),
      wallColor: const Color(0xFF8D5B2E),
      totalWaves: 6,
      obstacles: [
        const MapObstacle(position: Offset(600, 600), radius: 50, type: 'tree'),
        const MapObstacle(
          position: Offset(4000, 600),
          radius: 50,
          type: 'tree',
        ),
        const MapObstacle(
          position: Offset(600, 3000),
          radius: 50,
          type: 'tree',
        ),
        const MapObstacle(
          position: Offset(4000, 3000),
          radius: 50,
          type: 'tree',
        ),
      ],
      rivalCamps: [
        const RivalCampConfig(
          name: 'Bastión Orco del Este',
          position: Offset(4100, 1800),
          level: 2,
        ),
        const RivalCampConfig(
          name: 'Bastión Orco del Oeste',
          position: Offset(500, 1800),
          level: 2,
        ),
        const RivalCampConfig(
          name: 'Fortaleza Worg del Norte',
          position: Offset(2300, 450),
          level: 3,
        ),
      ],
    ),
    GameMapModel(
      id: 'level_3_snow',
      levelIndex: 3,
      name: 'Nivel 3: Cumbres Gélidas de Niflheim',
      subtitle: 'Reino Helado del Norte',
      difficultyText: 'Desafiante',
      description:
          'Un continente gélido gigante sumido en la niebla. Conoce a los druidas helados y destruye bastiones de nigromantes.',
      biome: MapBiomeType.snow,
      worldWidth: 4800,
      worldHeight: 3800,
      groundColor: const Color(0xFF596967),
      groundAccentColor: const Color(0xFF91A39C),
      pathColor: const Color(0xFF6C7A89),
      wallColor: const Color(0xFF495057),
      totalWaves: 7,
      obstacles: [
        const MapObstacle(position: Offset(600, 600), radius: 45, type: 'rock'),
        const MapObstacle(
          position: Offset(4200, 600),
          radius: 45,
          type: 'rock',
        ),
        const MapObstacle(
          position: Offset(600, 3200),
          radius: 45,
          type: 'rock',
        ),
        const MapObstacle(
          position: Offset(4200, 3200),
          radius: 45,
          type: 'rock',
        ),
      ],
      rivalCamps: [
        const RivalCampConfig(
          name: 'Campamento Esqueleto Helado',
          position: Offset(2400, 450),
          level: 3,
        ),
        const RivalCampConfig(
          name: 'Fortaleza del Hielo del Sur',
          position: Offset(2400, 3350),
          level: 3,
        ),
        const RivalCampConfig(
          name: 'Nido del Dragón Helado',
          position: Offset(4200, 1900),
          level: 4,
        ),
      ],
    ),
    GameMapModel(
      id: 'level_4_necro',
      levelIndex: 4,
      name: 'Nivel 4: Bastión Oscuro de las Sombras',
      subtitle: 'Tierras Desoladas del Apocalipsis',
      difficultyText: 'Difícil',
      description:
          'Vasto campo de batalla infernal. Salva a los civiles prisioneros, acepta misiones del gremio y repele la cruzada oscura.',
      biome: MapBiomeType.lava,
      worldWidth: 5000,
      worldHeight: 4000,
      groundColor: const Color(0xFF302A2C),
      groundAccentColor: const Color(0xFF4E414C),
      pathColor: const Color(0xFF4A304A),
      wallColor: const Color(0xFF6B2D6B),
      totalWaves: 8,
      obstacles: [
        const MapObstacle(position: Offset(800, 800), radius: 60, type: 'rock'),
        const MapObstacle(
          position: Offset(4200, 800),
          radius: 60,
          type: 'rock',
        ),
      ],
      rivalCamps: [
        const RivalCampConfig(
          name: 'Círculo Nigromántico del Norte',
          position: Offset(2500, 450),
          level: 4,
        ),
        const RivalCampConfig(
          name: 'Bastión Sombrío del Este',
          position: Offset(4400, 2000),
          level: 4,
        ),
        const RivalCampConfig(
          name: 'Bastión Sombrío del Oeste',
          position: Offset(600, 2000),
          level: 4,
        ),
      ],
    ),
    GameMapModel(
      id: 'level_5_titan',
      levelIndex: 5,
      name: 'Nivel 5: Volcán del Titán Infernus',
      subtitle: 'Guerra Continental por el Destino del Mundo',
      difficultyText: 'Extrema / Pesadilla',
      description:
          'Mapa colosal con guerras abiertas entre facciones, volcanes activos, ejércitos aliados NPC y enfrentamientos épicos.',
      biome: MapBiomeType.lava,
      worldWidth: 5500,
      worldHeight: 4200,
      groundColor: const Color(0xFF302A28),
      groundAccentColor: const Color(0xFF654333),
      pathColor: const Color(0xFF4A2828),
      wallColor: const Color(0xFF6B1D1D),
      totalWaves: 10,
      obstacles: [
        const MapObstacle(position: Offset(800, 800), radius: 70, type: 'lava'),
        const MapObstacle(
          position: Offset(4700, 3400),
          radius: 70,
          type: 'lava',
        ),
      ],
      rivalCamps: [
        const RivalCampConfig(
          name: 'Fortaleza Volcánica del Titán',
          position: Offset(2750, 500),
          level: 5,
        ),
        const RivalCampConfig(
          name: 'Asedio de Fuego del Sur',
          position: Offset(2750, 3700),
          level: 5,
        ),
        const RivalCampConfig(
          name: 'Nido de Demonios del Este',
          position: Offset(4800, 2100),
          level: 5,
        ),
        const RivalCampConfig(
          name: 'Ciudad Caída del Oeste',
          position: Offset(700, 2100),
          level: 5,
        ),
      ],
    ),
  ].map(_compact).toList();

  /// Dense, deterministic arenas with open roads between camp entrances.
  static GameMapModel _compact(GameMapModel source) {
    const scale = 0.43;
    final width = source.worldWidth * scale;
    final height = source.worldHeight * scale;
    final center = Offset(width / 2, height / 2);
    final camps = source.rivalCamps
        .map(
          (c) => RivalCampConfig(
            name: c.name,
            position: c.position * scale,
            level: c.level,
          ),
        )
        .toList();
    final props = <MapObstacle>[];
    for (int row = 1; row <= 5; row++) {
      for (int col = 1; col <= 6; col++) {
        final pos = Offset(
          width * col / 7 + (row.isEven ? 22 : -22),
          height * row / 6,
        );
        if ((pos - center).distance < 330 ||
            (pos.dx - center.dx).abs() < 105 ||
            (pos.dy - center.dy).abs() < 85 ||
            (pos - (center + const Offset(360, -240))).distance < 120 ||
            camps.any((c) => (c.position - pos).distance < 135)) {
          continue;
        }
        props.add(
          MapObstacle(
            position: pos,
            radius: 25 + (col % 3) * 5,
            type: source.biome == MapBiomeType.forest && (col + row).isOdd
                ? 'tree'
                : 'rock',
          ),
        );
      }
    }
    return GameMapModel(
      id: source.id,
      levelIndex: source.levelIndex,
      name: source.name,
      subtitle: source.subtitle,
      difficultyText: source.difficultyText,
      description: source.biome == MapBiomeType.snow
          ? 'Recupera la torre de escarcha del nordeste, destruye los campamentos y derrota al espectro.'
          : source.biome == MapBiomeType.lava
          ? 'Esquiva las erupciones anunciadas, destruye los bastiones y vence al dragón Infernus.'
          : 'Prepara tus defensas, conquista los campamentos y derrota al titán del valle.',
      biome: source.biome,
      worldWidth: width,
      worldHeight: height,
      groundColor: source.groundColor,
      groundAccentColor: source.groundAccentColor,
      pathColor: source.pathColor,
      wallColor: source.wallColor,
      totalWaves: source.totalWaves,
      obstacles: props,
      rivalCamps: camps,
    );
  }
}
