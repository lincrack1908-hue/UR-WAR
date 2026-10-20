import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/audio_engine.dart';
import '../../core/save_system.dart';
import '../graphics/battlefield_painter.dart';
import '../graphics/pixel_art_data.dart';
import 'enemy_ai.dart';
import '../models/enemy_type.dart';
import '../models/entity.dart';
import '../models/game_map.dart';
import '../models/npc_model.dart';
import '../models/player_class.dart';
import '../models/tutorial_hint.dart';
import '../models/wave_system.dart';

class GameEngine extends ChangeNotifier {
  final GameMapModel map;
  final PlayerClass playerClass;

  late PlayerEntity player;
  late VillageBuildingEntity townHall;
  final List<VillageBuildingEntity> villageBuildings = [];
  final List<EnemyEntity> enemies = [];
  final List<RivalCampEntity> rivalCamps = [];
  final List<NpcEntity> npcs = [];
  NpcEntity? activeDialogueNpc;
  final List<ProjectileEntity> projectiles = [];
  final List<FloatingTextEntity> floatingTexts = [];
  final List<ParticleEntity> particles = [];
  final List<RollingRockEntity> rollingRocks = [];
  late WaveSystem waveSystem;
  final List<HazardEntity> hazards = [];
  final List<CorpseEntity> corpses = [];
  double elapsedTime = 0;
  double damageDealt = 0;
  double damageTaken = 0;
  int buildingsLost = 0;
  int enemiesRevived = 0;
  int bossesDefeated = 0;
  int completedWaves = 0;
  double objectiveProgress = 0;
  int fortificationLevel = 0;
  double _eruptionTimer = 9;
  double _preparationIdleTimer = 0;
  BuildingType? pendingBuildingType;
  Offset? buildPreviewPosition;
  int _pendingBuildCost = 0;
  bool _hasExplicitAim = false;
  Offset? get objectivePosition => map.biome == MapBiomeType.snow
      ? townHall.position + const Offset(360, -240)
      : null;
  bool get objectiveComplete =>
      objectivePosition == null || objectiveProgress >= 1;
  String get objectiveText {
    final campsLeft = rivalCamps.where((c) => !c.isDestroyed).length;
    final extra = objectivePosition != null && !objectiveComplete
        ? ' · Recupera la torre del nordeste (${(objectiveProgress * 100).round()}%)'
        : '';
    return 'Oleadas $completedWaves/${map.totalWaves} · Campamentos pendientes: $campsLeft$extra';
  }

  // Niebla de Guerra (Fog of War)
  late int fogCols;
  late int fogRows;
  static const double fogTileSize = 100.0;
  late List<List<bool>> fogExplored;

  bool isGameOver = false;
  bool isVictory = false;
  bool isPaused = false;
  TutorialHint? activeTutorialHint;
  final List<TutorialHint> _pendingTutorialHints = [];
  String? announcementBanner;
  double announcementTimer = 0.0;

  // Efectos temporales definitivos
  double freezeTimer = 0.0;
  double villageShieldTimer = 0.0;

  // Seguimiento de cámara
  Offset cameraOffset = Offset.zero;
  Size viewportSize = const Size(800, 600);

  int _enemyIdCounter = 0;
  int _buildingIdCounter = 0;
  final Random _random = Random();
  final Set<String> _destroyedBuildingIds = {};

  double get villageIntegrity =>
      (townHall.health / townHall.maxHealth).clamp(0, 1);
  int get resultStars {
    if (!isVictory) return 0;
    return 1 +
        (villageIntegrity >= .5 ? 1 : 0) +
        (villageIntegrity >= .8 ? 1 : 0);
  }

  String get resultRank => !isVictory
      ? 'DEFENSA ROTA'
      : resultStars == 3
      ? 'GUARDIÁN LEGENDARIO'
      : resultStars == 2
      ? 'DEFENSOR VETERANO'
      : 'SUPERVIVIENTE';

  GameEngine({required this.map, required this.playerClass}) {
    _initializeGame();
  }

  void _initializeGame() {
    final centerX = map.worldWidth / 2;
    final centerY = map.worldHeight / 2;

    // Inicializar Niebla de Guerra
    fogCols = (map.worldWidth / fogTileSize).ceil();
    fogRows = (map.worldHeight / fogTileSize).ceil();
    fogExplored = List.generate(
      fogRows,
      (_) => List.generate(fogCols, (_) => false),
    );

    // Revelar la aldea inicial
    _revealFogArea(Offset(centerX, centerY), 350);

    // Crear al jugador
    player = PlayerEntity(
      position: Offset(centerX, centerY + 80),
      playerClass: playerClass,
    );

    // Crear el Salón Comunal (Corazón de la aldea)
    townHall = VillageBuildingEntity(
      id: 'town_hall',
      type: BuildingType.townHall,
      position: Offset(centerX, centerY),
      maxHealth: 1200,
      radius: 50,
    );
    villageBuildings.add(townHall);

    // Torres de vigilancia defensivas iniciales
    villageBuildings.add(
      VillageBuildingEntity(
        id: 'tower_nw',
        type: BuildingType.watchtower,
        position: Offset(centerX - 160, centerY - 120),
        maxHealth: 500,
        radius: 35,
      ),
    );
    villageBuildings.add(
      VillageBuildingEntity(
        id: 'tower_se',
        type: BuildingType.watchtower,
        position: Offset(centerX + 160, centerY + 120),
        maxHealth: 500,
        radius: 35,
      ),
    );

    // Cabañas iniciales
    villageBuildings.add(
      VillageBuildingEntity(
        id: 'cottage_ne',
        type: BuildingType.cottage,
        position: Offset(centerX + 140, centerY - 110),
        maxHealth: 350,
        radius: 35,
      ),
    );

    // Inicializar NPCs de la Aldea Isekai
    npcs.add(
      NpcEntity(
        id: 'npc_blacksmith',
        name: 'Gromm el Herrero',
        title: 'Maestro Forjador',
        role: NpcRoleType.blacksmith,
        position: Offset(centerX - 90, centerY + 90),
        dialogue:
            '¡Saludos, guerrero! Puedo forjar mejores armaduras para tus defensas a cambio de 100 de Oro.',
        sprite: PixelArtLibrary.npcBlacksmith,
        themeColor: const Color(0xFFFF8C00),
      ),
    );

    npcs.add(
      NpcEntity(
        id: 'npc_merchant',
        name: 'Kaelen el Mercader',
        title: 'Comerciante Isekai',
        role: NpcRoleType.merchant,
        position: Offset(centerX + 90, centerY + 90),
        dialogue:
            '¡Mercancías raras traídas de tierras lejanas! Compra elixires de salud instantáneos.',
        sprite: PixelArtLibrary.npcMerchant,
        themeColor: const Color(0xFF2A9D8F),
      ),
    );

    npcs.add(
      NpcEntity(
        id: 'npc_questgiver',
        name: 'Anciano Eldrin',
        title: 'Líder del Gremio',
        role: NpcRoleType.questGiver,
        position: Offset(centerX, centerY - 100),
        dialogue:
            'Nuestra aldea está bajo asedio constante. ¡Elimina a 10 enemigos de las hordas invasoras y te recompensaré con oro y gran experiencia!',
        sprite: PixelArtLibrary.npcQuestGiver,
        themeColor: const Color(0xFFFFD166),
        activeQuest: NpcQuest(
          id: 'quest_cleanse_horde',
          title: 'Purga de las Hordas Invasoras',
          description:
              'Elimina 10 enemigos que intenten destruir el Corazón de la Aldea.',
          requiredEnemyKills: 10,
          goldReward: 250,
          xpReward: 120,
        ),
      ),
    );

    // Inicializar campamentos enemigos rivales en el mapa
    for (int i = 0; i < map.rivalCamps.length; i++) {
      final config = map.rivalCamps[i];
      rivalCamps.add(
        RivalCampEntity(
          id: 'rival_$i',
          name: config.name,
          position: config.position,
          maxHealth: 450.0 + config.level * 100,
          goldReward: 350 + config.level * 50,
          xpReward: 160 + config.level * 40,
        ),
      );
    }

    // Inicializar sistema de oleadas
    waveSystem = WaveSystem(
      maxWaves: map.totalWaves,
      biome: map.biome,
      level: map.levelIndex,
    );
    player.gold = 200;
    showAnnouncement(
      'PREPARACIÓN: construye, explora y comienza cuando estés listo',
      5,
    );
    if (map.levelIndex == 1) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_welcome',
          title: 'GUÍA DE BATALLA',
          message:
              'Defiende el Salón Comunal y sobrevive a todas las oleadas. Explora la aldea antes de comenzar.',
          icon: Icons.shield,
        ),
      );
    }
    _updateCamera();
  }

  void dismissTutorialHint() {
    final dismissed = activeTutorialHint;
    if (dismissed == null) return;
    SaveSystem.markTutorialHintSeen(dismissed.id);
    activeTutorialHint = _pendingTutorialHints.isEmpty
        ? null
        : _pendingTutorialHints.removeAt(0);
    notifyListeners();
  }

  void disableTutorialHints() {
    activeTutorialHint = null;
    _pendingTutorialHints.clear();
    SaveSystem.setTutorialHintsEnabled(false);
    notifyListeners();
  }

  void _showTutorialHint(TutorialHint hint) {
    if (map.levelIndex != 1 ||
        !SaveSystem.tutorialHintsEnabled ||
        SaveSystem.hasSeenTutorialHint(hint.id) ||
        activeTutorialHint?.id == hint.id ||
        _pendingTutorialHints.any((pending) => pending.id == hint.id)) {
      return;
    }
    if (activeTutorialHint == null) {
      activeTutorialHint = hint;
    } else {
      _pendingTutorialHints.add(hint);
    }
    notifyListeners();
  }

  void showTutorialForBuildingType(BuildingType type) {
    final hint = switch (type) {
      BuildingType.watchtower => const TutorialHint(
        id: 'level1_item_watchtower',
        title: 'TORRE DE VIGILANCIA',
        message:
            'Dispara rápidamente a un enemigo. Colócala cerca de los caminos para cubrir los accesos.',
        icon: Icons.fort,
      ),
      BuildingType.frostTower => const TutorialHint(
        id: 'level1_item_frost_tower',
        title: 'TORRE DE ESCARCHA',
        message:
            'Ralentiza a los invasores. Combínala con otras torres para mantenerlos bajo ataque más tiempo.',
        icon: Icons.ac_unit,
      ),
      BuildingType.cannonTower => const TutorialHint(
        id: 'level1_item_cannon',
        title: 'TORRE DE ASEDIO',
        message:
            'Causa daño explosivo en área. Es costosa, pero muy eficaz contra grupos numerosos.',
        icon: Icons.flare,
      ),
      BuildingType.barricade => const TutorialHint(
        id: 'level1_item_barricade',
        title: 'BARRICADA',
        message:
            'Bloquea y desvía el avance enemigo. Úsala para proteger torres y ganar tiempo.',
        icon: Icons.fence,
      ),
      BuildingType.goldMine => const TutorialHint(
        id: 'level1_item_gold_mine',
        title: 'MINA DE ORO',
        message:
            'Produce oro periódicamente. Constrúyela en una zona protegida para financiar nuevas defensas.',
        icon: Icons.monetization_on,
      ),
      _ => const TutorialHint(
        id: 'level1_building',
        title: 'EDIFICIO DE LA ALDEA',
        message:
            'Toca un edificio para revisar su salud, repararlo o mejorarlo con oro.',
        icon: Icons.home_work,
      ),
    };
    _showTutorialHint(hint);
  }

  void showTutorialForShop() {
    _showTutorialHint(
      const TutorialHint(
        id: 'level1_shop',
        title: 'ARMERÍA DE LA ALDEA',
        message:
            'Usa el oro para reparar edificios, mejorar tu héroe o construir torres antes de iniciar una oleada.',
        icon: Icons.storefront,
      ),
    );
  }

  void showTutorialForInsufficientGold() {
    _showTutorialHint(
      const TutorialHint(
        id: 'level1_insufficient_gold',
        title: 'ORO INSUFICIENTE',
        message:
            'Derrota enemigos, supera oleadas o protege una mina para conseguir el oro que te falta.',
        icon: Icons.savings,
      ),
    );
  }

  void _damageVillageBuilding(VillageBuildingEntity building, double damage) {
    final previousHealth = building.health;
    building.takeDamage(damage);
    if (building.health >= previousHealth) return;
    if (building.isDead && _destroyedBuildingIds.add(building.id)) {
      buildingsLost++;
      AudioEngine.playRockImpact();
    }
    _showTutorialHint(
      building == townHall
          ? const TutorialHint(
              id: 'level1_town_hall_under_attack',
              title: '¡EL SALÓN ESTÁ BAJO ATAQUE!',
              message:
                  'Si el Salón Comunal es destruido perderás la batalla. Regresa y elimina a sus atacantes.',
              icon: Icons.crisis_alert,
            )
          : const TutorialHint(
              id: 'level1_defense_damaged',
              title: 'DEFENSA DAÑADA',
              message:
                  'Una estructura defensiva está recibiendo daño. Puedes repararla tocándola o desde la tienda.',
              icon: Icons.build,
            ),
    );
  }

  void interactWithNearbyNpc() {
    for (final npc in npcs) {
      final dist = (npc.position - player.position).distance;
      if (dist <= 75.0) {
        activeDialogueNpc = npc;
        notifyListeners();
        return;
      }
    }
  }

  void closeNpcDialogue() {
    activeDialogueNpc = null;
    notifyListeners();
  }

  void claimActiveQuest(NpcEntity npc) {
    final quest = npc.activeQuest;
    if (quest != null && quest.isCompleted && !quest.isClaimed) {
      quest.isClaimed = true;
      player.gold += quest.goldReward;
      player.addXp(quest.xpReward);
      AudioEngine.playCoin();
      showAnnouncement(
        '¡Misión Completada: ${quest.title}! +${quest.goldReward} Oro, +${quest.xpReward} XP',
      );
      notifyListeners();
    }
  }

  void setViewportSize(Size size) {
    viewportSize = size;
    _updateCamera();
  }

  void showAnnouncement(String text, [double duration = 3.0]) {
    announcementBanner = text;
    announcementTimer = duration;
  }

  void _revealFogArea(Offset pos, double radius) {
    final startCol = ((pos.dx - radius) / fogTileSize).floor().clamp(
      0,
      fogCols - 1,
    );
    final endCol = ((pos.dx + radius) / fogTileSize).ceil().clamp(
      0,
      fogCols - 1,
    );
    final startRow = ((pos.dy - radius) / fogTileSize).floor().clamp(
      0,
      fogRows - 1,
    );
    final endRow = ((pos.dy + radius) / fogTileSize).ceil().clamp(
      0,
      fogRows - 1,
    );

    for (int r = startRow; r <= endRow; r++) {
      for (int c = startCol; c <= endCol; c++) {
        final tileCenter = Offset(
          (c + 0.5) * fogTileSize,
          (r + 0.5) * fogTileSize,
        );
        if ((tileCenter - pos).distance <= radius) {
          fogExplored[r][c] = true;
        }
      }
    }
  }

  /// Actualización del bucle de juego (60 FPS)
  void update(double dt) {
    if (isGameOver || isVictory || isPaused || !dt.isFinite || dt <= 0) return;
    // Small fixed slices avoid tunnelling and preserve timer behaviour after a slow frame.
    var remaining = min(dt, 0.25);
    while (remaining > 0) {
      final step = min(remaining, 1 / 60);
      _step(step);
      remaining -= step;
      if (isGameOver || isVictory) break;
    }
    notifyListeners();
  }

  void _step(double dt) {
    elapsedTime += dt;
    final specialWasCoolingDown = player.specialSkillTimer > 0;
    player.attackTimer = max(0, player.attackTimer - dt);
    player.specialSkillTimer = max(0, player.specialSkillTimer - dt);
    player.ultimateSkillTimer = max(0, player.ultimateSkillTimer - dt);
    player.attackAnimTimer = max(0, player.attackAnimTimer - dt);
    player.hitFlashTimer = max(0, player.hitFlashTimer - dt);
    player.dashCooldown = max(0, player.dashCooldown - dt);
    player.shieldTimer = max(0, player.shieldTimer - dt);
    if (player.dashTimer > 0) {
      player.position = _moveWithCollision(
        player.position,
        player.dashDirection * 600 * dt,
        20,
      );
      player.dashTimer = max(0, player.dashTimer - dt);
    }
    freezeTimer = max(0, freezeTimer - dt);
    villageShieldTimer = max(0, villageShieldTimer - dt);
    if (player.isMoving) player.walkPhase += dt * 10;
    if (!waveSystem.isWaveInProgress && completedWaves == 0) {
      _preparationIdleTimer = player.isMoving ? 0 : _preparationIdleTimer + dt;
      if (_preparationIdleTimer >= 15) {
        _showTutorialHint(
          const TutorialHint(
            id: 'level1_preparation_idle',
            title: 'PREPARA LA DEFENSA',
            message:
                'Explora, construye una torre o pulsa “Iniciar oleada” cuando estés preparado para combatir.',
            icon: Icons.hourglass_bottom,
          ),
        );
      }
    } else {
      _preparationIdleTimer = 0;
    }
    if (specialWasCoolingDown && player.specialSkillTimer <= 0) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_special_ready',
          title: 'HABILIDAD LISTA',
          message:
              'Tu habilidad especial volvió a estar disponible. Úsala cuando varios enemigos estén cerca.',
          icon: Icons.auto_awesome,
        ),
      );
    }
    _revealFogArea(player.position, 240);
    _applyPassiveSkills(dt);
    if (announcementTimer > 0) {
      announcementTimer -= dt;
      if (announcementTimer <= 0) announcementBanner = null;
    }
    for (final spawn in waveSystem.update(
      dt,
      map.worldWidth,
      map.worldHeight,
    )) {
      _spawnEnemy(spawn.key, spawn.value, isWaveEnemy: true);
    }
    _updateRivalCamps(dt);
    _updateEnemies(dt);
    _updateRollingRocks(dt);
    _updateVillageDefenses(dt);
    _updateProjectiles(dt);
    _updateHazards(dt);
    _updateObjectives(dt);
    _updateVFX(dt);
    for (final corpse in corpses) {
      corpse.lifeTime -= dt;
      corpse.reviveWindow -= dt;
    }
    corpses.removeWhere((c) => c.reviveWindow <= 0);
    enemies.removeWhere((e) => e.isDead);
    if (player.health <= 0 || townHall.health <= 0) {
      isGameOver = true;
      AudioEngine.playDefeat();
      SaveSystem.addMatchStats(
        kills: player.kills,
        gold: player.gold,
        score: player.score,
      );
      showAnnouncement('LA DEFENSA HA CAÍDO', 10);
      return;
    }
    if (waveSystem.isWaveInProgress &&
        waveSystem.hasCompletedAllSpawns &&
        !enemies.any((e) => e.isWaveEnemy && !e.isDead)) {
      completedWaves = waveSystem.currentWave;
      waveSystem.startIntermission();
      if (completedWaves < map.totalWaves) waveSystem.currentWave++;
      player.gold += 60 + completedWaves * 20;
      player.addXp(45 + completedWaves * 15);
      showAnnouncement(
        completedWaves == map.totalWaves
            ? 'HORDAS VENCIDAS: completa los objetivos pendientes'
            : 'OLEADA SUPERADA: prepara tus defensas y pulsa Comenzar',
        5,
      );
    }
    if (completedWaves == map.totalWaves &&
        objectiveComplete &&
        rivalCamps.every((c) => c.isDestroyed) &&
        enemies.isEmpty) {
      isVictory = true;
      AudioEngine.playVictory();
      SaveSystem.addMatchStats(
        kills: player.kills,
        gold: player.gold,
        score: player.score,
      );
      SaveSystem.completeLevel(
        map.id,
        levelNumber: map.levelIndex,
        stars: resultStars,
        score: player.score,
      );
      showAnnouncement('¡VICTORIA! ALDEA DEFENDIDA Y TERRITORIO LIBERADO', 10);
    }
    _updateCamera();
  }

  void startNextWave() {
    if (isPaused ||
        isGameOver ||
        isVictory ||
        waveSystem.isWaveInProgress ||
        completedWaves >= map.totalWaves ||
        pendingBuildingType != null) {
      return;
    }
    waveSystem.startWave(completedWaves + 1, map.worldWidth, map.worldHeight);
    _preparationIdleTimer = 0;
    if (waveSystem.currentWave == 1) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_first_wave',
          title: 'PRIMERA OLEADA',
          message:
              'Los goblins son rápidos pero débiles. Mantén la distancia y deja que tus torres ayuden a derrotarlos.',
          icon: Icons.warning_amber,
        ),
      );
    }
    showAnnouncement('¡OLEADA ${waveSystem.currentWave}! Defiende la aldea', 2);
    notifyListeners();
  }

  void _updateObjectives(double dt) {
    final target = objectivePosition;
    if (target != null && !objectiveComplete) {
      if ((player.position - target).distance < 65 &&
          !enemies.any(
            (e) => !e.isDead && (e.position - target).distance < 120,
          )) {
        objectiveProgress = min(1, objectiveProgress + dt / 3);
        if (objectiveComplete) {
          final spec = BuildingSpec.forType(BuildingType.frostTower);
          villageBuildings.add(
            VillageBuildingEntity(
              id: 'reclaimed_tower',
              type: BuildingType.frostTower,
              position: target,
              maxHealth: spec.maxHealth,
              radius: spec.radius,
            ),
          );
          player.gold += 150;
          player.addXp(120);
          showAnnouncement('¡TORRE RECUPERADA! Escarcha aliada y +150 oro', 4);
        }
      }
    }
    if (map.biome == MapBiomeType.lava && waveSystem.isWaveInProgress) {
      _eruptionTimer -= dt;
      if (_eruptionTimer <= 0) {
        _eruptionTimer = 9;
        hazards.add(
          HazardEntity(
            position: player.position,
            radius: 75,
            damage: 45,
            color: Colors.deepOrangeAccent,
            delay: 1.6,
            type: 'eruption',
          ),
        );
      }
    }
  }

  void _applyPassiveSkills(double dt) {
    if (playerClass.type == PlayerRoleType.cleric &&
        player.unlockedSkillIds.contains('c_passive_1')) {
      // Aura Celestial: regenera torres de la aldea constantemente
      for (final b in villageBuildings) {
        if (!b.isDead) b.repair(5.0 * dt);
      }
    }
  }

  void _updateRivalCamps(double dt) {
    if (!waveSystem.isWaveInProgress) return;
    for (final camp in List<RivalCampEntity>.from(rivalCamps)) {
      if (camp.isDestroyed) continue;
      if (camp.hitFlashTimer > 0) camp.hitFlashTimer -= dt;

      camp.spawnTimer += dt;
      if (camp.spawnTimer >= 24.0 && enemies.length < 65) {
        camp.spawnTimer = 0.0;
        // Enviar invasor extra desde el campamento rival
        _spawnEnemy(
          _random.nextBool() ? EnemyConfig.orc : EnemyConfig.goblin,
          camp.position + const Offset(70, 0),
        );
      }
    }
  }

  void _updateCamera() {
    final targetX = player.position.dx - viewportSize.width / 2;
    final targetY = player.position.dy - viewportSize.height / 2;

    final maxX = max(0.0, map.worldWidth - viewportSize.width);
    final maxY = max(0.0, map.worldHeight - viewportSize.height);

    cameraOffset = Offset(targetX.clamp(0.0, maxX), targetY.clamp(0.0, maxY));
  }

  void movePlayer(Offset inputDirection, double dt) {
    if (isGameOver ||
        isVictory ||
        isPaused ||
        dt <= 0 ||
        !dt.isFinite ||
        player.dashTimer > 0) {
      return;
    }
    var direction = inputDirection;
    if (direction != Offset.zero) player.targetDestination = null;
    if (direction == Offset.zero && player.targetDestination != null) {
      direction = player.targetDestination! - player.position;
      if (direction.distance < 8) {
        player.targetDestination = null;
        direction = Offset.zero;
      }
    }
    player.isMoving = direction.distance > 0;
    if (!player.isMoving) return;
    direction /= direction.distance;
    player.moveDirection = direction;
    if (!_hasExplicitAim) player.aimDirection = direction;
    player.facingLeft = player.aimDirection.dx < 0;
    final speed = player.currentSpeed * (player.isBlocking ? 0.45 : 1);
    var remaining = min(dt, 0.25);
    while (remaining > 0) {
      final step = min(remaining, 1 / 60);
      player.position = _moveWithCollision(
        player.position,
        direction * speed * step,
        20,
      );
      remaining -= step;
    }
    _updateCamera();
  }

  void setAimDirection(Offset direction) {
    if (!direction.dx.isFinite ||
        !direction.dy.isFinite ||
        direction.distance < 0.01) {
      return;
    }
    _hasExplicitAim = true;
    player.aimDirection = direction / direction.distance;
    player.facingLeft = direction.dx < 0;
  }

  bool dodge() {
    if (isPaused || isVictory || isGameOver || player.dashCooldown > 0) {
      return false;
    }
    player.dashDirection = player.isMoving
        ? player.moveDirection
        : player.aimDirection;
    player.dashTimer = playerClass.type == PlayerRoleType.ranger ? 0.25 : 0.19;
    player.dashCooldown = playerClass.type == PlayerRoleType.ranger ? 2.0 : 3.0;
    player.isBlocking = false;
    player.targetDestination = null;
    if (playerClass.type == PlayerRoleType.ranger) {
      hazards.add(
        HazardEntity(
          position: player.position,
          radius: 55,
          damage: 30,
          color: Colors.lightGreenAccent,
          isFriendly: true,
          type: 'trap',
          delay: 0,
          duration: 8,
        ),
      );
    }
    return true;
  }

  void setBlocking(bool value) {
    player.isBlocking =
        value && playerClass.type == PlayerRoleType.knight && !isPaused;
    notifyListeners();
  }

  void toggleMageElement() {
    if (playerClass.type != PlayerRoleType.mage || isGameOver || isVictory) {
      return;
    }
    player.mageUsesIce = !player.mageUsesIce;
    notifyListeners();
  }

  bool _isOpen(Offset pos, double radius, {bool ignoreCamps = false}) {
    if (pos.dx < radius ||
        pos.dy < radius ||
        pos.dx > map.worldWidth - radius ||
        pos.dy > map.worldHeight - radius) {
      return false;
    }
    for (final o in map.obstacles) {
      if ((o.position - pos).distance < o.radius + radius) return false;
    }
    for (final b in villageBuildings) {
      if (!b.isDead && (b.position - pos).distance < b.radius + radius) {
        return false;
      }
    }
    if (!ignoreCamps) {
      for (final c in rivalCamps) {
        if (!c.isDestroyed && (c.position - pos).distance < c.radius + radius) {
          return false;
        }
      }
    }
    return true;
  }

  Offset _moveWithCollision(
    Offset pos,
    Offset delta,
    double radius, {
    bool steer = false,
  }) {
    final proposed = pos + delta;
    if (_isOpen(proposed, radius, ignoreCamps: steer)) return proposed;
    // Slide along a wall, then try tangents so enemies can go around scenery.
    final x = Offset(proposed.dx, pos.dy);
    if (delta.dx.abs() > 0.01 && _isOpen(x, radius, ignoreCamps: steer)) {
      return x;
    }
    final y = Offset(pos.dx, proposed.dy);
    if (delta.dy.abs() > 0.01 && _isOpen(y, radius, ignoreCamps: steer)) {
      return y;
    }
    if (steer && delta.distance > 0) {
      for (final angle in [pi / 4, -pi / 4, pi / 2, -pi / 2]) {
        final turned = Offset(
          delta.dx * cos(angle) - delta.dy * sin(angle),
          delta.dx * sin(angle) + delta.dy * cos(angle),
        );
        if (_isOpen(pos + turned, radius, ignoreCamps: true)) {
          return pos + turned;
        }
      }
    }
    return pos;
  }

  void setTargetDestination(Offset worldPos) {
    if (isGameOver || isVictory || isPaused) return;
    const padding = 30.0;
    final clampedX = worldPos.dx.clamp(padding, map.worldWidth - padding);
    final clampedY = worldPos.dy.clamp(padding, map.worldHeight - padding);
    player.targetDestination = Offset(clampedX, clampedY);
    notifyListeners();
  }

  void clearTargetDestination() {
    player.targetDestination = null;
    notifyListeners();
  }

  /// Ejecución de ataque primario
  void attack() {
    if (isGameOver || isVictory || isPaused) return;
    if (player.attackTimer > 0) return;

    // Pasiva de la Cazadora: Ojo de Águila (+30% velocidad de ataque)
    final cooldownBonus =
        (playerClass.type == PlayerRoleType.ranger &&
            player.unlockedSkillIds.contains('r_passive_1'))
        ? 0.7
        : 1.0;

    player.attackTimer = playerClass.attackCooldownSeconds * cooldownBonus;
    player.attackAnimTimer = 0.25;

    if (playerClass.isMelee) {
      AudioEngine.playAttackSlash();
    } else {
      AudioEngine.playShoot();
    }

    final attackDir = player.aimDirection;

    if (playerClass.isMelee) {
      final hitCenter =
          player.position + attackDir * (playerClass.attackRange * 0.6);
      final hitRadius = playerClass.attackRange;

      _spawnSlashParticles(
        hitCenter,
        player.facingLeft,
        playerClass.themeColor,
      );

      // Daño a enemigos
      for (final enemy in enemies) {
        final dist = (enemy.position - hitCenter).distance;
        if (dist <= hitRadius) {
          final isCrit = _random.nextDouble() < 0.25;
          final dmg = isCrit
              ? player.currentDamage * 1.6
              : player.currentDamage;
          _damageEnemy(enemy, dmg, isCrit: isCrit);

          final pushDir = (enemy.position - player.position);
          if (pushDir.distance > 0) {
            enemy.position += (pushDir / pushDir.distance) * 20.0;
          }
        }
      }

      // Daño a campamentos rivales
      for (final camp in rivalCamps) {
        if (camp.isDestroyed) continue;
        if ((camp.position - hitCenter).distance <= hitRadius + camp.radius) {
          _damageRivalCamp(camp, player.currentDamage);
        }
      }
    } else {
      final shootDir = player.aimDirection;
      final isMage = playerClass.type == PlayerRoleType.mage;

      projectiles.add(
        ProjectileEntity(
          position: player.position,
          velocity: shootDir * (isMage ? 320.0 : 480.0),
          damage: player.currentDamage,
          radius: isMage ? 8.0 : 4.0,
          color: isMage
              ? (player.mageUsesIce
                    ? Colors.lightBlueAccent
                    : const Color(0xFFF72585))
              : const Color(0xFFFFD166),
          isFromPlayer: true,
          isExplosive: isMage && !player.mageUsesIce,
          slowDuration: isMage && player.mageUsesIce ? 2.5 : 0,
          explosionRadius: isMage ? 65.0 : 0.0,
          pierceCount: isMage ? 1 : 2,
        ),
      );
    }
  }

  /// Habilidad especial
  void useSpecialSkill() {
    if (isGameOver || isVictory || isPaused) return;
    if (player.specialSkillTimer > 0) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_special_cooldown',
          title: 'HABILIDAD EN RECARGA',
          message:
              'Espera a que el contador llegue a cero. Mientras tanto, sigue moviéndote y usa tu ataque básico.',
          icon: Icons.timer_outlined,
        ),
      );
      return;
    }

    player.specialSkillTimer = playerClass.specialSkillCooldownSeconds;
    AudioEngine.playSpecialSkill();

    switch (playerClass.type) {
      case PlayerRoleType.knight:
        showAnnouncement('¡TORBELLINO DE ACERO!', 1.2);
        _spawnExplosionParticles(player.position, Colors.redAccent, 40);
        for (final enemy in enemies) {
          final dist = (enemy.position - player.position).distance;
          if (dist <= 140) {
            _damageEnemy(enemy, 130, isCrit: true);
            final push = (enemy.position - player.position);
            if (push.distance > 0) {
              enemy.position += (push / push.distance) * 60.0;
            }
          }
        }
        break;

      case PlayerRoleType.ranger:
        showAnnouncement('¡LLUVIA DE FLECHAS!', 1.2);
        final baseAngle = atan2(player.aimDirection.dy, player.aimDirection.dx);
        const arrowCount = 9;
        const spreadAngle = pi * 0.7;
        for (int i = 0; i < arrowCount; i++) {
          final angle =
              baseAngle -
              (spreadAngle / 2) +
              (spreadAngle / (arrowCount - 1)) * i;
          final dir = Offset(cos(angle), sin(angle));
          projectiles.add(
            ProjectileEntity(
              position: player.position,
              velocity: dir * 520,
              damage: player.currentDamage * 1.3,
              radius: 4.0,
              color: const Color(0xFF55A630),
              isFromPlayer: true,
              pierceCount: 3,
            ),
          );
        }
        break;

      case PlayerRoleType.mage:
        showAnnouncement('¡METEORO CATACLÍSMICO!', 1.5);
        hazards.add(
          HazardEntity(
            position: player.position + player.aimDirection * 180,
            radius: 130,
            damage: 180,
            color: player.mageUsesIce
                ? Colors.lightBlueAccent
                : Colors.purpleAccent,
            isFriendly: true,
            delay: .55,
            type: player.mageUsesIce ? 'ice' : 'meteor',
          ),
        );
        break;

      case PlayerRoleType.cleric:
        showAnnouncement('¡BENDICIÓN SAGRADA!', 1.5);
        hazards.add(
          HazardEntity(
            position: player.position,
            radius: 140,
            damage: 15,
            color: Colors.amberAccent,
            isFriendly: true,
            type: 'sanctuary',
            delay: 0,
            duration: 5,
          ),
        );
        player.shieldTimer = 1;
        player.heal(90);
        townHall.repair(250);
        for (final b in villageBuildings) {
          if (b != townHall) b.repair(150);
        }
        _spawnExplosionParticles(player.position, Colors.amberAccent, 40);
        _spawnExplosionParticles(townHall.position, Colors.amberAccent, 40);
        break;
    }
  }

  /// Habilidad definitiva (Ultimate) desbloqueable a Nivel 5
  void useUltimateSkill() {
    if (isGameOver || isVictory || isPaused) return;
    if (!player.unlockedSkillIds.contains(
      '${playerClass.type.name.substring(0, 1)}_ultimate',
    )) {
      return;
    }
    if (player.ultimateSkillTimer > 0) return;

    final ultimateSkill = playerClass.skillTree.firstWhere((s) => s.isUltimate);
    player.ultimateSkillTimer = ultimateSkill.cooldownSeconds;

    switch (playerClass.type) {
      case PlayerRoleType.knight:
        showAnnouncement('¡IMPACTO SÍSMICO ULTIMATE!', 2.0);
        _spawnExplosionParticles(player.position, const Color(0xFFFFD166), 70);
        for (final enemy in List<EnemyEntity>.from(enemies)) {
          if ((enemy.position - player.position).distance <= 220) {
            _damageEnemy(enemy, 250, isCrit: true);
          }
        }
        break;

      case PlayerRoleType.ranger:
        showAnnouncement('¡FLECHA DEL DRAGÓN ULTIMATE!', 2.0);
        final dir = player.aimDirection;
        projectiles.add(
          ProjectileEntity(
            position: player.position,
            velocity: dir * 650,
            damage: 350,
            radius: 16.0,
            color: const Color(0xFFFF5400),
            isFromPlayer: true,
            isExplosive: true,
            explosionRadius: 120,
            pierceCount: 10,
          ),
        );
        break;

      case PlayerRoleType.mage:
        showAnnouncement('¡TORMENTA DE ESCARCHA ULTIMATE!', 2.0);
        freezeTimer = 6.0;
        _spawnExplosionParticles(player.position, const Color(0xFF00BBF9), 80);
        break;

      case PlayerRoleType.cleric:
        showAnnouncement('¡ESCUDO DIVINO ULTIMATE!', 2.0);
        villageShieldTimer = 6.0;
        _spawnExplosionParticles(
          townHall.position,
          const Color(0xFFFFD166),
          80,
        );
        break;
    }
  }

  void unlockSkill(String skillId) {
    if (player.skillPoints <= 0 || player.unlockedSkillIds.contains(skillId)) {
      return;
    }
    final skill = playerClass.skillTree.firstWhere((s) => s.id == skillId);
    if (player.level < skill.requiredLevel) return;

    player.skillPoints--;
    player.unlockedSkillIds.add(skillId);

    // Aplicar pasiva si corresponde
    if (skill.isPassive && playerClass.type == PlayerRoleType.knight) {
      player.damageReduction = 0.25;
    }

    showAnnouncement('¡HABILIDAD DESBLOQUEADA: ${skill.name}!', 2.5);
    notifyListeners();
  }

  // ==========================================
  // CONSTRUCCIÓN DE LA ALDEA Y ESTRUCTURAS
  // ==========================================
  bool canPlaceStructure(BuildingType type, Offset position) {
    if (!position.dx.isFinite ||
        !position.dy.isFinite ||
        type == BuildingType.townHall) {
      return false;
    }
    final spec = BuildingSpec.forType(type);
    if ((position - townHall.position).distance > 430) return false;
    if (!_isOpen(position, spec.radius + 14)) return false;
    if ((position - player.position).distance < spec.radius + 24) return false;
    if (npcs.any((n) => (position - n.position).distance < spec.radius + 30)) {
      return false;
    }
    final col = (position.dx / fogTileSize).floor();
    final row = (position.dy / fogTileSize).floor();
    return row >= 0 &&
        row < fogRows &&
        col >= 0 &&
        col < fogCols &&
        fogExplored[row][col];
  }

  bool beginConstruction(BuildingType type, int cost) {
    final price = BuildingSpec.forType(type).cost;
    if (player.gold < price) {
      showTutorialForInsufficientGold();
      return false;
    }
    if (isGameOver ||
        isVictory ||
        type == BuildingType.townHall ||
        cost != price ||
        villageBuildings.where((b) => !b.isDead).length >= 30) {
      return false;
    }
    pendingBuildingType = type;
    _pendingBuildCost = price;
    buildPreviewPosition = null;
    player.targetDestination = null;
    notifyListeners();
    return true;
  }

  void setBuildPreview(Offset position) {
    if (pendingBuildingType == null ||
        !position.dx.isFinite ||
        !position.dy.isFinite) {
      return;
    }
    buildPreviewPosition = Offset(
      (position.dx / 10).round() * 10.0,
      (position.dy / 10).round() * 10.0,
    );
    notifyListeners();
  }

  bool confirmConstruction() {
    final type = pendingBuildingType;
    final position = buildPreviewPosition;
    if (type == null ||
        position == null ||
        !canPlaceStructure(type, position) ||
        player.gold < _pendingBuildCost) {
      if (player.gold < _pendingBuildCost) showTutorialForInsufficientGold();
      return false;
    }
    final spec = BuildingSpec.forType(type);
    player.gold -= _pendingBuildCost;
    villageBuildings.add(
      VillageBuildingEntity(
        id: 'custom_b_${++_buildingIdCounter}',
        type: type,
        position: position,
        maxHealth: spec.maxHealth,
        radius: spec.radius,
      ),
    );
    pendingBuildingType = null;
    buildPreviewPosition = null;
    _pendingBuildCost = 0;
    AudioEngine.playCoin();
    showAnnouncement('${spec.name} construida', 2);
    notifyListeners();
    return true;
  }

  void cancelConstruction() {
    pendingBuildingType = null;
    buildPreviewPosition = null;
    _pendingBuildCost = 0;
    notifyListeners();
  }

  // Compatibility entry point: automated callers can choose a valid free site.
  // The player-facing shop always uses begin/preview/confirm.
  bool buildStructure(BuildingType type, int cost) {
    if (!beginConstruction(type, cost)) return false;
    for (var radius = 140.0; radius <= 320; radius += 60) {
      for (var i = 0; i < 24; i++) {
        final pos =
            townHall.position +
            Offset(cos(i * pi / 12), sin(i * pi / 12)) * radius;
        if (canPlaceStructure(type, pos)) {
          setBuildPreview(pos);
          if (confirmConstruction()) return true;
        }
      }
    }
    cancelConstruction();
    return false;
  }

  bool upgradeBuilding(String id) {
    final building = villageBuildings.where((b) => b.id == id).firstOrNull;
    if (building != null && player.gold < building.upgradeCost) {
      showTutorialForInsufficientGold();
      return false;
    }
    if (building == null ||
        building.isDead ||
        building.level >= 3 ||
        player.gold < building.upgradeCost) {
      return false;
    }
    player.gold -= building.upgradeCost;
    building.level++;
    building.maxHealth += BuildingSpec.forType(building.type).maxHealth * .35;
    building.repair(building.maxHealth * .35);
    AudioEngine.playCoin();
    notifyListeners();
    return true;
  }

  bool repairBuilding(String id) {
    final building = villageBuildings.where((b) => b.id == id).firstOrNull;
    if (building != null && player.gold < building.repairCost) {
      showTutorialForInsufficientGold();
      return false;
    }
    if (building == null ||
        building.isDead ||
        building.health >= building.maxHealth ||
        player.gold < building.repairCost) {
      return false;
    }
    player.gold -= building.repairCost;
    building.repair(building.maxHealth);
    AudioEngine.playCoin();
    notifyListeners();
    return true;
  }

  bool fortifyVillage() {
    if (player.gold < 100) {
      showTutorialForInsufficientGold();
      return false;
    }
    if (fortificationLevel >= 3) return false;
    player.gold -= 100;
    fortificationLevel++;
    for (final b in villageBuildings.where((b) => !b.isDead)) {
      b.maxHealth += 100;
      b.repair(100);
    }
    AudioEngine.playCoin();
    showAnnouncement(
      'Fortificación $fortificationLevel/3 · +100 salud por edificio',
    );
    notifyListeners();
    return true;
  }

  void setPaused(bool value) {
    if (isPaused == value) return;
    isPaused = value;
    if (value) {
      player.isBlocking = false;
      player.isMoving = false;
    }
    notifyListeners();
  }

  void _spawnEnemy(
    EnemyConfig config,
    Offset position, {
    bool isWaveEnemy = false,
  }) {
    _enemyIdCounter++;
    final wave = waveSystem.currentWave;
    enemies.add(
      EnemyEntity(
        id: 'enemy_$_enemyIdCounter',
        isWaveEnemy: isWaveEnemy,
        config: config,
        position: position,
        healthScale: EnemyDifficulty.healthScaleForWave(wave),
        damageScale: EnemyDifficulty.damageScaleForWave(wave),
        speedScale: EnemyDifficulty.speedScaleForWave(wave),
      ),
    );

    if (config.isBoss) {
      showAnnouncement(
        config.ability == EnemyAbility.diamondResurrection
            ? '¡MINIJEFE: ${config.name}! Impide que complete su formación'
            : '¡JEFE: ${config.name}! Evita sus zonas de ataque',
        4.0,
      );
    }
    if (config.category == EnemyCategory.goblin) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_goblin',
          title: 'GOBLIN SAQUEADOR',
          message:
              'Es rápido y ataca en grupo. Elimínalo antes de que llegue a tus edificios.',
          icon: Icons.directions_run,
        ),
      );
    }
    if (config.category == EnemyCategory.orc) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_orc',
          title: 'ORCO BERSERKER',
          message:
              'Tiene mucha vida y golpea fuerte. Debilítalo con torres antes de enfrentarlo.',
          icon: Icons.security,
        ),
      );
    }
  }

  void _hurtPlayer(double damage, Offset source) {
    final direction = source - player.position;
    final facing = direction.distance > 0
        ? (direction.dx * player.aimDirection.dx +
                  direction.dy * player.aimDirection.dy) /
              direction.distance
        : 1.0;
    final previousHealth = player.health;
    player.takeDamage(damage * (player.isBlocking && facing > 0.3 ? 0.25 : 1));
    damageTaken += max(0, previousHealth - player.health);
    if (player.health > 0 && player.health <= player.maxHealth * .35) {
      _showTutorialHint(
        const TutorialHint(
          id: 'level1_low_health',
          title: 'SALUD BAJA',
          message:
              'Retrocede, esquiva los ataques y compra una Poción de vitalidad en la tienda.',
          icon: Icons.favorite_border,
        ),
      );
    }
  }

  void _updateHazards(double dt) {
    for (final h in hazards) {
      if (h.delay > 0) {
        h.delay -= dt;
        if (h.delay > 0) continue;
      }
      h.duration -= dt;
      final visualOnly =
          h.type == 'necromancy' ||
          h.type == 'graveRise' ||
          h.type == 'soulLink';
      if (visualOnly) {
        if (!h.triggered) {
          h.triggered = true;
          _spawnExplosionParticles(h.position, h.color, 10);
        }
        continue;
      }
      if (h.type == 'trap' &&
          !enemies.any(
            (e) => !e.isDead && (e.position - h.position).distance <= h.radius,
          )) {
        continue;
      }
      h.tickTimer -= dt;
      final repeating = h.type == 'sanctuary';
      if (h.triggered && (!repeating || h.tickTimer > 0)) continue;
      h.triggered = true;
      h.tickTimer = 1;
      if (!repeating) {
        _spawnExplosionParticles(h.position, h.color, 14);
        AudioEngine.playMagicImpact();
      }
      if (h.isFriendly) {
        if (repeating) {
          if ((player.position - h.position).distance <= h.radius) {
            player.heal(h.damage);
          }
          for (final b in villageBuildings) {
            if (!b.isDead && (b.position - h.position).distance <= h.radius) {
              b.health = min(b.maxHealth, b.health + h.damage);
            }
          }
        } else {
          for (final e in List<EnemyEntity>.from(enemies)) {
            if (!e.isDead &&
                (e.position - h.position).distance <=
                    h.radius + e.config.hitRadius) {
              _damageEnemy(e, h.damage);
              if (h.type == 'ice' || h.type == 'trap') {
                e.slowTimer = 3;
                e.slowFactor = 0.35;
              }
            }
          }
          for (final c in rivalCamps) {
            if (!c.isDestroyed &&
                (c.position - h.position).distance <= h.radius + c.radius) {
              _damageRivalCamp(c, h.damage);
            }
          }
          if (h.type == 'trap') h.duration = 0;
        }
      } else {
        if ((player.position - h.position).distance <= h.radius + 20) {
          _hurtPlayer(h.damage, h.position);
        }
        if (villageShieldTimer <= 0) {
          for (final b in villageBuildings) {
            if (!b.isDead &&
                (b.position - h.position).distance <= h.radius + b.radius) {
              _damageVillageBuilding(b, h.damage);
            }
          }
        }
      }
    }
    hazards.removeWhere((h) => h.delay <= 0 && h.duration <= 0);
  }

  void _updateEnemies(double dt) {
    for (final enemy in List<EnemyEntity>.from(enemies)) {
      if (enemy.isDead) continue;
      _updateEnemyTimers(enemy, dt);
      if (enemy.emergenceTimer > 0) continue;
      if (_maintainGuardFormation(enemy, dt)) continue;
      _tryEnemyAbility(enemy, dt);
      final target =
          _selectGuardThreat(enemy) ??
          _selectCoordinatedTarget(enemy) ??
          _selectEnemyTarget(enemy);
      final difference = target.position - enemy.position;
      final distance = difference.distance;
      _updateEnemyFacing(enemy, difference);

      final movementIntent = EnemyMovementPolicy.intentFor(
        enemy: enemy,
        target: target,
      );
      if (movementIntent == EnemyMovementIntent.retreat) {
        _updateEnemyMovement(enemy, target, dt, retreat: true);
        continue;
      }

      if (_isEnemyTargetInRange(enemy, target, distance)) {
        _tryEnemyAttack(enemy, target, difference, distance);
      } else {
        _updateEnemyMovement(enemy, target, dt);
      }
    }

    enemies.removeWhere((e) => e.isDead);
  }

  void _updateEnemyTimers(EnemyEntity enemy, double dt) {
    if (enemy.attackTimer > 0) enemy.attackTimer -= dt;
    if (enemy.hitFlashTimer > 0) enemy.hitFlashTimer -= dt;
    enemy.walkPhase += dt * 8;
    enemy.slowTimer = max(0, enemy.slowTimer - dt);
    enemy.emergenceTimer = max(0, enemy.emergenceTimer - dt);
    enemy.vulnerableTimer = max(0, enemy.vulnerableTimer - dt);
  }

  void _updateRollingRocks(double dt) {
    for (final rock in rollingRocks) {
      rock.lifeTime -= dt;
      if (rock.isExpired) continue;
      rock.position += rock.velocity * dt;
      rock.rotation += rock.velocity.distance * dt / rock.radius;

      final outsideWorld =
          rock.position.dx < -rock.radius ||
          rock.position.dy < -rock.radius ||
          rock.position.dx > map.worldWidth + rock.radius ||
          rock.position.dy > map.worldHeight + rock.radius;
      final hitObstacle = map.obstacles.any(
        (obstacle) =>
            (obstacle.position - rock.position).distance <=
            obstacle.radius + rock.radius,
      );
      if (outsideWorld || hitObstacle) {
        _breakRollingRock(rock);
        continue;
      }

      if ((player.position - rock.position).distance <= rock.radius + 20) {
        _hurtPlayer(rock.damage, rock.position);
        _breakRollingRock(rock);
        continue;
      }
      if (villageShieldTimer <= 0) {
        for (final building in villageBuildings) {
          if (building.isDead) continue;
          if ((building.position - rock.position).distance <=
              building.radius + rock.radius) {
            _damageVillageBuilding(building, rock.damage);
            _breakRollingRock(rock);
            break;
          }
        }
      }
    }
    rollingRocks.removeWhere((rock) => rock.isExpired);
  }

  void _breakRollingRock(RollingRockEntity rock) {
    if (rock.isExpired) return;
    rock.lifeTime = 0;
    _spawnExplosionParticles(rock.position, const Color(0xFFB08968), 12);
    AudioEngine.playRockImpact();
  }

  void _tryEnemyAbility(EnemyEntity enemy, double dt) {
    switch (enemy.config.ability) {
      case EnemyAbility.none:
        return;
      case EnemyAbility.healOrRevive:
        _trySupportAbility(enemy, dt);
        return;
      case EnemyAbility.diamondResurrection:
        _tryDiamondResurrection(enemy, dt);
        return;
      case EnemyAbility.areaStrike:
        _tryAreaStrike(enemy, dt);
        return;
      case EnemyAbility.titanArsenal:
        _tryTitanArsenal(enemy, dt);
        return;
      case EnemyAbility.frostStorm:
        _tryElementalBossAbility(enemy, dt, frost: true);
        return;
      case EnemyAbility.lavaBurst:
        _tryElementalBossAbility(enemy, dt, frost: false);
        return;
    }
  }

  void _updateBossPhase(EnemyEntity enemy) {
    final nextPhase = enemy.health < enemy.maxHealth * 0.5 ? 2 : 1;
    if (nextPhase > enemy.phase) {
      enemy.phase = nextPhase;
      showAnnouncement('¡${enemy.config.name} ENTRA EN FASE $nextPhase!', 3);
      AudioEngine.playBossAbility();
      _spawnExplosionParticles(enemy.position, enemy.config.healthBarColor, 28);
    }
  }

  void _setBossCooldown(EnemyEntity enemy) {
    final base = enemy.config.abilityCooldownSeconds > 0
        ? enemy.config.abilityCooldownSeconds
        : 6.0;
    enemy.abilityTimer = enemy.phase == 2 ? max(3.5, base * .62) : base;
  }

  void _openBossWeakPoint(EnemyEntity enemy) {
    enemy.vulnerableTimer = enemy.phase == 2 ? 2.2 : 2.8;
    floatingTexts.add(
      FloatingTextEntity(
        position: enemy.position - const Offset(0, 95),
        text: '¡PUNTO DÉBIL!',
        color: const Color(0xFFFFD166),
        fontSize: 15,
      ),
    );
  }

  void _tryTitanArsenal(EnemyEntity enemy, double dt) {
    _updateBossPhase(enemy);
    enemy.abilityTimer -= dt;
    if (enemy.abilityTimer > 0) return;

    enemy.abilityCastCount++;
    if (enemy.abilityCastCount.isOdd) {
      showAnnouncement('¡GOLPE SÍSMICO! Sal de las grietas', 2);
      hazards.add(
        HazardEntity(
          position: player.position,
          radius: enemy.phase == 2 ? 135 : 105,
          damage: enemy.attackDamage * 1.55,
          color: const Color(0xFFFF9F1C),
          delay: 1.25,
          duration: .65,
          type: 'titanSlam',
        ),
      );
    } else {
      showAnnouncement('¡AVALANCHA! Esquiva las rocas rodantes', 2);
      _launchRollingRocks(enemy);
    }
    AudioEngine.playBossAbility();
    _openBossWeakPoint(enemy);
    _setBossCooldown(enemy);
  }

  void _launchRollingRocks(EnemyEntity enemy) {
    var direction = player.position - enemy.position;
    direction = direction.distance > 0
        ? direction / direction.distance
        : const Offset(1, 0);
    final baseAngle = atan2(direction.dy, direction.dx);
    final count = enemy.phase == 2 ? 5 : 3;
    final spread = enemy.phase == 2 ? .9 : .55;
    for (var index = 0; index < count; index++) {
      final ratio = count == 1 ? 0.0 : index / (count - 1);
      final angle = baseAngle - spread / 2 + spread * ratio;
      final velocity =
          Offset(cos(angle), sin(angle)) * (enemy.phase == 2 ? 275.0 : 235.0);
      rollingRocks.add(
        RollingRockEntity(
          position: enemy.position + Offset(cos(angle), sin(angle)) * 48,
          velocity: velocity,
          damage: enemy.attackDamage * .9,
          radius: enemy.phase == 2 ? 23 : 20,
        ),
      );
    }
    AudioEngine.playRockLaunch();
  }

  void _tryElementalBossAbility(
    EnemyEntity enemy,
    double dt, {
    required bool frost,
  }) {
    _updateBossPhase(enemy);
    enemy.abilityTimer -= dt;
    if (enemy.abilityTimer > 0) return;

    final positions = <Offset>[player.position];
    if (enemy.phase == 2) {
      positions.addAll([
        player.position + const Offset(100, 0),
        player.position + const Offset(-100, 0),
      ]);
    }
    for (final position in positions) {
      hazards.add(
        HazardEntity(
          position: position,
          radius: frost ? 110 : 100,
          damage: enemy.attackDamage * 1.35,
          color: frost ? Colors.lightBlueAccent : Colors.deepOrangeAccent,
          delay: frost ? 1.45 : 1.05,
          duration: .7,
          type: frost ? 'iceStorm' : 'lavaBurst',
        ),
      );
    }
    showAnnouncement(frost ? '¡TORMENTA DE HIELO!' : '¡ERUPCIÓN INFERNAL!', 2);
    AudioEngine.playBossAbility();
    _openBossWeakPoint(enemy);
    _setBossCooldown(enemy);
  }

  void _tryAreaStrike(EnemyEntity enemy, double dt) {
    _updateBossPhase(enemy);
    enemy.abilityTimer -= dt;
    if (enemy.abilityTimer > 0) return;

    final baseCooldown = enemy.config.abilityCooldownSeconds > 0
        ? enemy.config.abilityCooldownSeconds
        : 6.0;
    enemy.abilityTimer = enemy.phase == 2
        ? max(3.5, baseCooldown * .58)
        : baseCooldown;
    hazards.add(
      HazardEntity(
        position: player.position,
        radius: enemy.phase == 2 ? 100 : 75,
        damage: enemy.attackDamage * 1.5,
        color: Colors.deepOrange,
        delay: 1.2,
        duration: .6,
        type: 'titanSlam',
      ),
    );
  }

  void _tryDiamondResurrection(EnemyEntity enemy, double dt) {
    _updateBossPhase(enemy);
    enemy.abilityTimer -= dt;
    if (enemy.abilityTimer > 0) return;

    const formation = [
      Offset(0, -95),
      Offset(95, 0),
      Offset(0, 95),
      Offset(-95, 0),
    ];
    final occupiedOffsets = enemies
        .where(
          (candidate) =>
              !candidate.isDead && candidate.guardLeaderId == enemy.id,
        )
        .map((candidate) => candidate.guardOffset)
        .toSet();
    var summoned = 0;
    for (final offset in formation) {
      if (occupiedOffsets.contains(offset)) continue;
      _enemyIdCounter++;
      final position = enemy.position + offset;
      enemies.add(
        EnemyEntity(
          id: 'enemy_$_enemyIdCounter',
          config: EnemyConfig.skeleton,
          position: position,
          isWaveEnemy: enemy.isWaveEnemy,
          canBeRevived: false,
          grantsReward: false,
          guardLeaderId: enemy.id,
          guardOffset: offset,
          emergenceTimer: 1.2,
          healthScale: enemy.maxHealth / enemy.config.maxHealth,
          damageScale: enemy.damageScale,
          speedScale: enemy.speedScale,
        ),
      );
      hazards.add(
        HazardEntity(
          position: position,
          radius: 42,
          damage: 0,
          color: const Color(0xFF70E000),
          delay: 0,
          duration: 1.2,
          type: 'graveRise',
        ),
      );
      _spawnHitParticles(position, const Color(0xFF70E000));
      summoned++;
    }

    if (summoned > 0) {
      floatingTexts.add(
        FloatingTextEntity(
          position: enemy.position - const Offset(0, 75),
          text: '¡RESURRECCIÓN!',
          color: const Color(0xFF70E000),
          fontSize: 17,
        ),
      );
      showAnnouncement(
        '¡RESURRECCIÓN! Destruye la formación que protege a Malachar',
        3,
      );
      enemiesRevived += summoned;
      AudioEngine.playResurrection();
    }
    final baseCooldown = enemy.config.abilityCooldownSeconds;
    enemy.abilityTimer = enemy.phase == 2
        ? max(6, baseCooldown * 0.7)
        : baseCooldown;
  }

  void _trySupportAbility(EnemyEntity enemy, double dt) {
    enemy.abilityTimer -= dt;
    if (enemy.abilityTimer > 0) return;

    final range = enemy.config.attackRange + 40;
    final corpse = EnemySupportPolicy.nearestRevivableCorpse(
      origin: enemy.position,
      corpses: corpses,
      range: range,
    );
    if (corpse != null) {
      corpses.remove(corpse);
      _enemyIdCounter++;
      final revived = EnemyEntity(
        id: 'enemy_$_enemyIdCounter',
        config: corpse.config,
        position: corpse.position,
        isWaveEnemy: corpse.isWaveEnemy,
        canBeRevived: false,
        healthScale: corpse.healthScale,
        damageScale: corpse.damageScale,
        speedScale: corpse.speedScale,
      )..health *= 0.45;
      enemies.add(revived);
      enemiesRevived++;
      hazards.add(
        HazardEntity(
          position: corpse.position,
          radius: 44,
          damage: 0,
          color: const Color(0xFF70E000),
          delay: 0,
          duration: 1.1,
          type: 'necromancy',
        ),
      );
      floatingTexts.add(
        FloatingTextEntity(
          position: corpse.position - const Offset(0, 35),
          text: '¡REVIVIDO!',
          color: const Color(0xFF70E000),
          fontSize: 14,
        ),
      );
      _spawnHitParticles(corpse.position, const Color(0xFF70E000));
      AudioEngine.playResurrection();
      enemy.abilityTimer = enemy.config.abilityCooldownSeconds;
      return;
    }

    final ally = EnemySupportPolicy.mostWoundedAlly(
      supporter: enemy,
      enemies: enemies,
      range: range,
    );
    if (ally == null) {
      enemy.abilityTimer = 1;
      return;
    }

    final healing = ally.maxHealth * 0.3;
    ally.health = min(ally.maxHealth, ally.health + healing);
    floatingTexts.add(
      FloatingTextEntity(
        position: ally.position - const Offset(0, 35),
        text: '+${healing.toInt()}',
        color: const Color(0xFF70E000),
        fontSize: 14,
      ),
    );
    _spawnHitParticles(ally.position, const Color(0xFF70E000));
    hazards.add(
      HazardEntity(
        position: ally.position,
        radius: 35,
        damage: 0,
        color: const Color(0xFF70E000),
        delay: 0,
        duration: .75,
        type: 'soulLink',
      ),
    );
    AudioEngine.playMagicImpact();
    enemy.abilityTimer = enemy.config.abilityCooldownSeconds;
  }

  EnemyTargetSelection _selectEnemyTarget(EnemyEntity enemy) {
    return EnemyTargetingPolicy.select(
      enemy: enemy,
      playerPosition: player.position,
      townHall: townHall,
      buildings: villageBuildings,
    );
  }

  EnemyTargetSelection? _selectCoordinatedTarget(EnemyEntity enemy) {
    if (EnemyCoordinationPolicy.isPackAlerted(
      enemy: enemy,
      enemies: enemies,
      playerPosition: player.position,
    )) {
      return EnemyTargetSelection.player(player.position);
    }
    return null;
  }

  EnemyEntity? _guardLeader(EnemyEntity enemy) {
    final leaderId = enemy.guardLeaderId;
    if (leaderId == null) return null;
    for (final candidate in enemies) {
      if (candidate.id == leaderId && !candidate.isDead) return candidate;
    }
    return null;
  }

  bool _maintainGuardFormation(EnemyEntity enemy, double dt) {
    final leader = _guardLeader(enemy);
    if (leader == null) return false;
    if ((player.position - leader.position).distance <= 330) return false;

    final destination = leader.position + enemy.guardOffset;
    final difference = destination - enemy.position;
    _updateEnemyFacing(enemy, difference);
    if (difference.distance > 12) {
      final direction = difference / difference.distance;
      enemy.position = _moveWithCollision(
        enemy.position,
        direction * enemy.movementSpeed * dt,
        enemy.config.hitRadius,
        steer: true,
      );
    }
    return true;
  }

  EnemyTargetSelection? _selectGuardThreat(EnemyEntity enemy) {
    final leader = _guardLeader(enemy);
    if (leader == null) return null;
    if ((player.position - leader.position).distance <= 330) {
      return EnemyTargetSelection.player(player.position);
    }
    return null;
  }

  void _updateEnemyFacing(EnemyEntity enemy, Offset difference) {
    if (difference.dx < -5) enemy.facingLeft = true;
    if (difference.dx > 5) enemy.facingLeft = false;
  }

  bool _isEnemyTargetInRange(
    EnemyEntity enemy,
    EnemyTargetSelection target,
    double distance,
  ) => distance <= enemy.config.attackRange + (target.building?.radius ?? 20);

  void _tryEnemyAttack(
    EnemyEntity enemy,
    EnemyTargetSelection target,
    Offset difference,
    double distance,
  ) {
    if (enemy.attackTimer > 0) return;
    enemy.attackTimer = enemy.config.attackCooldownSeconds;

    if (enemy.config.isRanged) {
      final shootDirection = distance > 0
          ? difference / distance
          : const Offset(1, 0);
      projectiles.add(
        ProjectileEntity(
          position: enemy.position,
          velocity: shootDirection * 280,
          damage: enemy.attackDamage,
          radius: 4.0,
          color:
              enemy.config.category == EnemyCategory.necromancer ||
                  enemy.config.category == EnemyCategory.necromancerMiniboss
              ? const Color(0xFF70E000)
              : const Color(0xFFE8E8E8),
          isFromPlayer: false,
        ),
      );
      return;
    }

    if (target.targetsPlayer) {
      _hurtPlayer(enemy.attackDamage, enemy.position);
      floatingTexts.add(
        FloatingTextEntity(
          position: player.position - const Offset(0, 20),
          text: '-${enemy.attackDamage.toInt()}',
          color: Colors.redAccent,
        ),
      );
      return;
    }

    if (villageShieldTimer > 0) return;
    final targetBuilding = target.building ?? townHall;
    _damageVillageBuilding(targetBuilding, enemy.attackDamage);
    floatingTexts.add(
      FloatingTextEntity(
        position: targetBuilding.position - const Offset(0, 30),
        text: '-${enemy.attackDamage.toInt()}',
        color: Colors.redAccent,
      ),
    );
  }

  void _updateEnemyMovement(
    EnemyEntity enemy,
    EnemyTargetSelection target,
    double dt, {
    bool retreat = false,
  }) {
    var movementTarget = target.position;
    if (target.targetsPlayer &&
        enemy.config.behavior == EnemyBehavior.raider &&
        !retreat) {
      movementTarget += EnemyCoordinationPolicy.flankOffset(enemy.id);
    }
    final difference = movementTarget - enemy.position;
    if (difference.distance <= 0) return;
    var moveDirection =
        difference / difference.distance * (retreat ? -1.0 : 1.0);
    final separation = EnemyCoordinationPolicy.separation(
      enemy: enemy,
      enemies: enemies,
    );
    if (separation.distance > 0) {
      final combined = moveDirection + separation * 0.65;
      if (combined.distance > 0) moveDirection = combined / combined.distance;
    }
    enemy.position = _moveWithCollision(
      enemy.position,
      moveDirection *
          enemy.movementSpeed *
          (enemy.slowTimer > 0 ? enemy.slowFactor : 1) *
          dt,
      enemy.config.hitRadius,
      steer: true,
    );
  }

  void _updateVillageDefenses(double dt) {
    for (final b in villageBuildings) {
      if (b.isDead) continue;
      if (b.hitFlashTimer > 0) b.hitFlashTimer -= dt;

      final spec = BuildingSpec.forType(b.type);
      if (spec.damage > 0) {
        b.shootTimer += dt;
        if (b.shootTimer >= spec.cooldown) {
          final target = _findNearestEnemy(b.position, spec.range);
          if (target != null) {
            b.shootTimer = 0;
            final diff = target.position - b.position;
            final direction = diff.distance > 0
                ? diff / diff.distance
                : const Offset(1, 0);
            projectiles.add(
              ProjectileEntity(
                position: b.position,
                velocity: direction * 400,
                damage: spec.damage * (1 + 0.35 * (b.level - 1)),
                radius: b.type == BuildingType.cannonTower ? 8 : 4,
                color: b.type == BuildingType.frostTower
                    ? Colors.lightBlueAccent
                    : const Color(0xFFFFD166),
                isFromPlayer: true,
                isExplosive: b.type == BuildingType.cannonTower,
                explosionRadius: 90,
                slowDuration: b.type == BuildingType.frostTower ? 2.5 : 0,
              ),
            );
          }
        }
      } else if (b.type == BuildingType.goldMine &&
          waveSystem.isWaveInProgress) {
        b.goldGenerationTimer += dt;
        if (b.goldGenerationTimer >= 10.0) {
          b.goldGenerationTimer = 0.0;
          player.gold += 15;
          floatingTexts.add(
            FloatingTextEntity(
              position: b.position - const Offset(0, 25),
              text: '+15 🪙 (MINA)',
              color: const Color(0xFFFFD166),
              fontSize: 12,
            ),
          );
        }
      }
    }
  }

  void _updateProjectiles(double dt) {
    for (final p in List<ProjectileEntity>.from(projectiles)) {
      p.lifeTime -= dt;
      p.position += p.velocity * dt;

      if (p.isExpired) continue;

      if (p.isFromPlayer) {
        // Impacto a enemigos
        for (final enemy in List<EnemyEntity>.from(enemies)) {
          if (enemy.isDead || p.hitTargetIds.contains(enemy.id)) continue;
          final dist = (enemy.position - p.position).distance;
          if (dist <= enemy.config.hitRadius + p.radius) {
            p.hitTargetIds.add(enemy.id);
            p.pierceCount--;
            if (p.slowDuration > 0) {
              enemy.slowTimer = p.slowDuration;
              enemy.slowFactor = p.slowFactor;
            }

            if (p.isExplosive) {
              _spawnExplosionParticles(p.position, const Color(0xFFF72585), 25);
              for (final splashTarget in List<EnemyEntity>.from(enemies)) {
                if ((splashTarget.position - p.position).distance <=
                    p.explosionRadius) {
                  _damageEnemy(splashTarget, p.damage);
                }
              }
              p.lifeTime = 0;
              break;
            } else {
              _damageEnemy(enemy, p.damage);
              if (p.pierceCount <= 0) {
                p.lifeTime = 0;
                break;
              }
            }
          }
        }

        if (p.isExpired) continue;
        // Impacto a campamentos rivales
        for (final camp in List<RivalCampEntity>.from(rivalCamps)) {
          if (camp.isDestroyed) continue;
          if ((camp.position - p.position).distance <= camp.radius + p.radius) {
            _damageRivalCamp(camp, p.damage);
            p.lifeTime = 0;
            break;
          }
        }
      } else {
        final distPlayer = (player.position - p.position).distance;
        if (distPlayer <= 25) {
          _hurtPlayer(p.damage, p.position - p.velocity * dt);
          floatingTexts.add(
            FloatingTextEntity(
              position: player.position - const Offset(0, 20),
              text: '-${p.damage.toInt()}',
              color: Colors.redAccent,
            ),
          );
          p.lifeTime = 0;
          continue;
        }

        if (villageShieldTimer <= 0) {
          for (final b in villageBuildings) {
            if (b.isDead) continue;
            if ((b.position - p.position).distance <= b.radius) {
              _damageVillageBuilding(b, p.damage);
              floatingTexts.add(
                FloatingTextEntity(
                  position: b.position - const Offset(0, 25),
                  text: '-${p.damage.toInt()}',
                  color: Colors.redAccent,
                ),
              );
              p.lifeTime = 0;
              break;
            }
          }
        }
      }
    }

    projectiles.removeWhere((p) => p.isExpired);
  }

  void _damageEnemy(EnemyEntity enemy, double amount, {bool isCrit = false}) {
    if (enemy.isDead || enemy.rewardGranted || amount <= 0) return;
    final effectiveAmount = amount * (enemy.vulnerableTimer > 0 ? 1.5 : 1);
    final previousHealth = enemy.health;
    enemy.takeDamage(effectiveAmount);
    final dealt = max(0, previousHealth - enemy.health);
    damageDealt += dealt;
    final weakPointHit = enemy.vulnerableTimer > 0;

    floatingTexts.add(
      FloatingTextEntity(
        position: enemy.position - const Offset(0, 25),
        text: weakPointHit
            ? '¡DÉBIL! -${dealt.toInt()}'
            : isCrit
            ? '¡CRÍTICO! -${dealt.toInt()}'
            : '-${dealt.toInt()}',
        color: (isCrit || weakPointHit)
            ? const Color(0xFFFFD166)
            : Colors.white,
        fontSize: (isCrit || weakPointHit) ? 16 : 13,
      ),
    );

    _spawnHitParticles(
      enemy.position,
      enemy.config.sprite.palette['g'] ?? Colors.red,
    );

    if (enemy.isDead) {
      enemy.rewardGranted = true;
      if (enemy.config.isBoss) bossesDefeated++;
      corpses.add(
        CorpseEntity(
          position: enemy.position,
          sprite: enemy.config.sprite,
          config: enemy.config,
          facingLeft: enemy.facingLeft,
          isWaveEnemy: enemy.isWaveEnemy,
          canBeRevived: enemy.canBeRevived,
          healthScale: enemy.maxHealth / enemy.config.maxHealth,
          damageScale: enemy.damageScale,
          speedScale: enemy.speedScale,
        ),
      );
      if (enemy.grantsReward) {
        player.gold += enemy.config.goldReward;
        player.score += enemy.config.scoreReward;
        player.kills++;
        player.addXp(enemy.config.xpReward);

        // Pasiva del Mago Arcano: Sifón de Maná (recupera vida al matar)
        if (playerClass.type == PlayerRoleType.mage &&
            player.unlockedSkillIds.contains('m_passive_1')) {
          player.heal(15);
        }

        floatingTexts.add(
          FloatingTextEntity(
            position: enemy.position - const Offset(0, 45),
            text:
                '+${enemy.config.goldReward} 🪙 | +${enemy.config.scoreReward} XP',
            color: const Color(0xFFFFD166),
            fontSize: 13,
          ),
        );

        // Actualizar progreso de misiones activas de NPCs
        for (final npc in npcs) {
          final q = npc.activeQuest;
          if (q != null && !q.isCompleted) {
            q.currentKills++;
            if (q.currentKills >= q.requiredEnemyKills) {
              q.isCompleted = true;
              showAnnouncement(
                '¡MISIÓN LISTA PARA RECLAMAR EN EL GREMIO: ${q.title}!',
              );
              AudioEngine.playLevelUp();
            }
          }
        }
      }

      _spawnDeathParticles(enemy.position);
    }
  }

  void _damageRivalCamp(RivalCampEntity camp, double amount) {
    if (camp.isDestroyed || amount <= 0) return;
    camp.takeDamage(amount);

    floatingTexts.add(
      FloatingTextEntity(
        position: camp.position - const Offset(0, 30),
        text: '-${amount.toInt()}',
        color: const Color(0xFFFF5400),
        fontSize: 15,
      ),
    );

    if (camp.isDestroyed) {
      player.gold += camp.goldReward;
      player.score += camp.xpReward;
      player.addXp(camp.xpReward);

      // Revelar niebla al destruir el campamento
      _revealFogArea(camp.position, 400);

      showAnnouncement(
        '¡CAMPAMENTO RIVAL ${camp.name.toUpperCase()} DESTRUIDO!',
        3.0,
      );

      floatingTexts.add(
        FloatingTextEntity(
          position: camp.position - const Offset(0, 50),
          text: '¡BOTÍN RIVAL! +${camp.goldReward} 🪙 +${camp.xpReward} XP',
          color: const Color(0xFFFFD166),
          fontSize: 16,
        ),
      );

      _spawnExplosionParticles(camp.position, const Color(0xFFFFD166), 60);
    }
  }

  EnemyEntity? _findNearestEnemy(Offset pos, double maxRadius) {
    EnemyEntity? nearest;
    double minDistance = maxRadius;
    for (final e in enemies) {
      if (e.isDead) continue;
      final d = (e.position - pos).distance;
      if (d < minDistance) {
        minDistance = d;
        nearest = e;
      }
    }
    return nearest;
  }

  void _updateVFX(double dt) {
    for (final ft in floatingTexts) {
      ft.lifeTime -= dt;
      ft.position -= const Offset(0, 25) * dt;
    }
    floatingTexts.removeWhere((ft) => ft.isExpired);

    for (final p in particles) {
      p.lifeTime -= dt;
      p.position += p.velocity * dt;
    }
    particles.removeWhere((p) => p.isExpired);
  }

  void _spawnHitParticles(Offset pos, Color color) {
    for (int i = 0; i < 6; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40.0 + _random.nextDouble() * 80.0;
      particles.add(
        ParticleEntity(
          position: pos,
          velocity: Offset(cos(angle), sin(angle)) * speed,
          color: color,
          radius: 2.0 + _random.nextDouble() * 2.0,
          lifeTime: 0.35,
        ),
      );
    }
  }

  void _spawnDeathParticles(Offset pos) {
    for (int i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60.0 + _random.nextDouble() * 120.0;
      particles.add(
        ParticleEntity(
          position: pos,
          velocity: Offset(cos(angle), sin(angle)) * speed,
          color: _random.nextBool()
              ? const Color(0xFFFFD166)
              : const Color(0xFFEF233C),
          radius: 3.0 + _random.nextDouble() * 3.0,
          lifeTime: 0.6,
        ),
      );
    }
  }

  void _spawnExplosionParticles(Offset pos, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50.0 + _random.nextDouble() * 180.0;
      particles.add(
        ParticleEntity(
          position: pos,
          velocity: Offset(cos(angle), sin(angle)) * speed,
          color: color,
          radius: 3.0 + _random.nextDouble() * 4.0,
          lifeTime: 0.7,
        ),
      );
    }
  }

  void _spawnSlashParticles(Offset pos, bool facingLeft, Color color) {
    final baseAngle = facingLeft ? pi : 0.0;
    for (int i = 0; i < 12; i++) {
      final angle = baseAngle - 0.6 + (_random.nextDouble() * 1.2);
      final speed = 100.0 + _random.nextDouble() * 90.0;
      particles.add(
        ParticleEntity(
          position: pos,
          velocity: Offset(cos(angle), sin(angle)) * speed,
          color: color,
          radius: 3.0,
          lifeTime: 0.25,
        ),
      );
    }
  }

  // ==========================================
  // OPERACIONES DE LA TIENDA DE LA ALDEA
  // ==========================================
  bool repairVillage(int cost, double hp) {
    if (player.gold < cost) {
      showTutorialForInsufficientGold();
      return false;
    }
    player.gold -= cost;
    townHall.repair(hp);
    for (final b in villageBuildings) {
      if (b != townHall) {
        b.repair(hp * 0.5);
      }
    }
    floatingTexts.add(
      FloatingTextEntity(
        position: townHall.position - const Offset(0, 40),
        text: '+${hp.toInt()} HP ALDEA',
        color: Colors.greenAccent,
        fontSize: 18,
      ),
    );
    notifyListeners();
    return true;
  }

  bool upgradeHeroDamage(int cost) {
    if (player.gold < cost) {
      showTutorialForInsufficientGold();
      return false;
    }
    player.gold -= cost;
    player.damageMultiplier += 0.25;
    floatingTexts.add(
      FloatingTextEntity(
        position: player.position - const Offset(0, 30),
        text: '¡DAÑO +25%!',
        color: const Color(0xFFFFD166),
        fontSize: 16,
      ),
    );
    notifyListeners();
    return true;
  }

  bool upgradeHeroSpeed(int cost) {
    if (player.gold < cost) {
      showTutorialForInsufficientGold();
      return false;
    }
    player.gold -= cost;
    player.speedMultiplier += 0.15;
    floatingTexts.add(
      FloatingTextEntity(
        position: player.position - const Offset(0, 30),
        text: '¡VELOCIDAD +15%!',
        color: const Color(0xFF00BBF9),
        fontSize: 16,
      ),
    );
    notifyListeners();
    return true;
  }

  bool healHero(int cost) {
    if (player.gold < cost) {
      showTutorialForInsufficientGold();
      return false;
    }
    if (player.health >= player.maxHealth) return false;
    player.gold -= cost;
    player.heal(player.maxHealth * 0.6);
    floatingTexts.add(
      FloatingTextEntity(
        position: player.position - const Offset(0, 30),
        text: '+VIDA COMPLETA',
        color: Colors.greenAccent,
        fontSize: 16,
      ),
    );
    notifyListeners();
    return true;
  }

  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  @override
  void dispose() {
    BattlefieldPainter.clearCache();
    super.dispose();
  }
}
