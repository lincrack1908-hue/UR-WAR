import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../core/audio_engine.dart';
import '../core/save_system.dart';
import '../game/graphics/battlefield_painter.dart';
import '../game/logic/game_engine.dart';
import '../game/models/entity.dart';
import '../game/models/game_map.dart';
import '../game/models/npc_model.dart';
import '../game/models/player_class.dart';
import '../game/widgets/game_hud.dart';
import '../game/widgets/game_over_dialog.dart';
import '../game/widgets/village_shop_dialog.dart';
import '../game/widgets/virtual_joystick.dart';
import 'settings_screen.dart';

class VillageDefenseScreen extends StatefulWidget {
  final GameMapModel mapModel;
  final PlayerClass playerClass;
  const VillageDefenseScreen({
    super.key,
    required this.mapModel,
    required this.playerClass,
  });
  @override
  State<VillageDefenseScreen> createState() => _VillageDefenseScreenState();
}

class _VillageDefenseScreenState extends State<VillageDefenseScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late GameEngine _engine;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode(debugLabel: 'Battle controls');
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Offset _moveDirection = Offset.zero;
  Offset _aimDirection = Offset.zero;
  Offset? _mousePosition;
  bool _mouseHeld = false;
  bool _aimHeld = false;
  bool _modalOpen = false;
  bool _appActive = true;
  bool _leaving = false;
  bool _hadFocus = false;
  bool _pausedBeforeConstruction = false;
  int _inputGeneration = 0;

  bool get _finished => _engine.isGameOver || _engine.isVictory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = GameEngine(map: widget.mapModel, playerClass: widget.playerClass);
    _ticker = createTicker(_onTick)..start();
    AudioEngine.startMusic('battle');
    // The first level uses contextual HUD hints. Full controls remain
    // available through the help button.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (!_appActive) {
      _clearInput();
      _engine.setPaused(true);
      AudioEngine.suspend();
    } else {
      // Returning to the app always requires an explicit Resume.
      AudioEngine.resume();
      if (mounted) setState(() {});
    }
  }

  void _clearInput() {
    _pressedKeys.clear();
    _moveDirection = Offset.zero;
    _aimDirection = Offset.zero;
    _mousePosition = null;
    _mouseHeld = false;
    _aimHeld = false;
    _inputGeneration++;
    _engine.clearTargetDestination();
    _engine.setBlocking(false);
  }

  int? _binding(String action) => SaveSystem.data.keyBindings[action];
  bool _held(String action) =>
      _pressedKeys.any((k) => k.keyId == _binding(action));
  bool _matches(KeyEvent event, String action) =>
      event.logicalKey.keyId == _binding(action);

  Offset _keyboardDirection() {
    var x = 0.0;
    var y = 0.0;
    if (_held('moveLeft') ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      x--;
    }
    if (_held('moveRight') ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      x++;
    }
    if (_held('moveUp') || _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      y--;
    }
    if (_held('moveDown') ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      y++;
    }
    final value = Offset(x, y);
    return value.distance > 1 ? value / value.distance : value;
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? .016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    if (!mounted || _engine.isPaused || _finished || _modalOpen) return;
    final step = dt.clamp(.001, .05);
    final keyboard = _keyboardDirection();
    _engine.movePlayer(
      keyboard != Offset.zero ? keyboard : _moveDirection,
      step,
    );
    if (_mousePosition != null) {
      _engine.setAimDirection(
        _mousePosition! + _engine.cameraOffset - _engine.player.position,
      );
    } else if (_aimDirection.distance > .1) {
      _engine.setAimDirection(_aimDirection);
    } else if (SaveSystem.data.aimAssist) {
      _assistAim();
    }
    if (_mouseHeld ||
        _aimHeld ||
        _held('attack') ||
        SaveSystem.data.autoAttack) {
      _engine.attack();
    }
    _engine.update(step);
  }

  void _assistAim() {
    Offset? nearest;
    var distance = _engine.player.playerClass.attackRange + 65;
    for (final position in [
      ..._engine.enemies.where((e) => !e.isDead).map((e) => e.position),
      ..._engine.rivalCamps.where((c) => !c.isDestroyed).map((c) => c.position),
    ]) {
      final d = (position - _engine.player.position).distance;
      if (d < distance) {
        distance = d;
        nearest = position;
      }
    }
    if (nearest != null) {
      _engine.setAimDirection(nearest - _engine.player.position);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_modalOpen) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        _engine.setBlocking(false);
      }
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (_matches(event, 'pause') ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_engine.pendingBuildingType != null) {
        _finishConstruction(false);
      } else if (!_finished) {
        _togglePause();
      }
      return KeyEventResult.handled;
    }
    if (_engine.isPaused || _finished) return KeyEventResult.ignored;
    _pressedKeys.add(event.logicalKey);
    if (_matches(event, 'special')) _engine.useSpecialSkill();
    if (_matches(event, 'dash')) _engine.dodge();
    if (_matches(event, 'shop')) _showShop();
    if (_matches(event, 'interact')) _talk();
    if (event.logicalKey == LogicalKeyboardKey.keyU) _engine.useUltimateSkill();
    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      if (widget.playerClass.type == PlayerRoleType.mage) {
        _engine.toggleMageElement();
      } else {
        _engine.setBlocking(true);
      }
    }
    return KeyEventResult.handled;
  }

  void _togglePause() {
    _clearInput();
    _engine.setPaused(!_engine.isPaused);
    if (!_engine.isPaused) _focusNode.requestFocus();
  }

  Future<void> _modal(Future<void> Function() show) async {
    if (_modalOpen || _finished) return;
    final wasPaused = _engine.isPaused;
    _clearInput();
    setState(() => _modalOpen = true);
    _engine.setPaused(true);
    try {
      await show();
    } finally {
      if (mounted && !_leaving) {
        _clearInput();
        setState(() => _modalOpen = false);
        if (_engine.pendingBuildingType != null) {
          _pausedBeforeConstruction = wasPaused;
        } else {
          _engine.setPaused(wasPaused || !_appActive);
        }
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _showShop() => _modal(() {
    _engine.showTutorialForShop();
    return showDialog<void>(
      context: context,
      builder: (_) => VillageShopDialog(engine: _engine),
    );
  });

  Future<void> _showHelp() => _modal(() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Defiende tu aldea'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Prepara tus defensas y pulsa Iniciar oleada cuando estés listo.',
              ),
              SizedBox(height: 12),
              Text(
                '2. Muévete con WASD o el joystick izquierdo. Apunta con el ratón y mantén clic para atacar. En móvil, mantén y arrastra el joystick derecho.',
              ),
              SizedBox(height: 12),
              Text(
                '3. Espacio: ataque · E: habilidad · Mayús: esquiva · F: hablar · B: tienda · Esc: pausa. U: definitiva. Q: bloquear (caballero) o cambiar elemento (mago). Puedes cambiar las teclas en Ajustes.',
              ),
              SizedBox(height: 12),
              Text(
                '4. Toca un edificio para repararlo o mejorarlo. En la tienda, elige una construcción, señala un terreno libre y confirma.',
              ),
              SizedBox(height: 12),
              Text(
                '5. Completa las oleadas y los objetivos del mapa. El minimapa muestra tu posición blanca, aldea azul y campamentos rojos.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡ENTENDIDO!'),
          ),
        ],
      ),
    );
    SaveSystem.setTutorialSeen(true);
  });

  Future<void> _showSettings() => _modal(
    () => Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const SettingsScreen())),
  );

  Future<void> _talk() async {
    if (_modalOpen || _finished) return;
    _engine.interactWithNearbyNpc();
    final npc = _engine.activeDialogueNpc;
    if (npc == null) return;
    await _modal(
      () => showDialog<void>(
        context: context,
        builder: (context) => AnimatedBuilder(
          animation: _engine,
          builder: (context, _) {
            final quest = npc.activeQuest;
            return AlertDialog(
              title: Text(npc.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(npc.title, style: TextStyle(color: npc.themeColor)),
                    const SizedBox(height: 10),
                    Text(npc.dialogue),
                    const SizedBox(height: 12),
                    Text('Tu oro: ${_engine.player.gold}'),
                    if (npc.role == NpcRoleType.merchant ||
                        npc.role == NpcRoleType.alchemist)
                      FilledButton.icon(
                        onPressed:
                            _engine.player.gold >= 60 &&
                                _engine.player.health < _engine.player.maxHealth
                            ? () => _engine.healHero(60)
                            : null,
                        icon: const Icon(Icons.favorite),
                        label: const Text('Poción · 60 oro'),
                      ),
                    if (npc.role == NpcRoleType.blacksmith) ...[
                      FilledButton(
                        onPressed: _engine.player.gold >= 100
                            ? () => _engine.fortifyVillage()
                            : null,
                        child: const Text('Fortificar defensas · 100 oro'),
                      ),
                      OutlinedButton(
                        onPressed: _engine.player.gold >= 120
                            ? () => _engine.upgradeHeroDamage(120)
                            : null,
                        child: const Text('Forjar arma · 120 oro'),
                      ),
                    ],
                    if (quest != null) ...[
                      const Divider(),
                      Text(
                        quest.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${quest.currentKills}/${quest.requiredEnemyKills} enemigos · ${quest.goldReward} oro + ${quest.xpReward} XP',
                      ),
                      FilledButton(
                        onPressed: quest.isCompleted && !quest.isClaimed
                            ? () => _engine.claimActiveQuest(npc)
                            : null,
                        child: Text(
                          quest.isClaimed
                              ? 'Recompensa recibida'
                              : 'Cobrar recompensa',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        ),
      ),
    );
    _engine.closeNpcDialogue();
  }

  Future<void> _inspectBuilding(VillageBuildingEntity building) => _modal(() {
    _engine.showTutorialForBuildingType(building.type);
    return showDialog<void>(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _engine,
        builder: (context, _) => AlertDialog(
          title: Text(BuildingSpec.forType(building.type).name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel ${building.level} · ${building.health.ceil()}/${building.maxHealth.ceil()} salud',
                ),
                const SizedBox(height: 10),
                Text('Oro disponible: ${_engine.player.gold}'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      building.health < building.maxHealth &&
                          _engine.player.gold >= building.repairCost
                      ? () => _engine.repairBuilding(building.id)
                      : null,
                  child: Text('Reparar · ${building.repairCost} oro'),
                ),
                FilledButton(
                  onPressed:
                      building.level < 3 &&
                          _engine.player.gold >= building.upgradeCost
                      ? () => _engine.upgradeBuilding(building.id)
                      : null,
                  child: Text(
                    building.level >= 3
                        ? 'Nivel máximo'
                        : 'Mejorar · ${building.upgradeCost} oro',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  });

  void _fieldDown(PointerDownEvent event) {
    if (_finished || _modalOpen) return;
    final world = event.localPosition + _engine.cameraOffset;
    if (_engine.pendingBuildingType != null) {
      _engine.setBuildPreview(world);
      return;
    }
    if (_engine.isPaused) return;
    _focusNode.requestFocus();
    for (final building in _engine.villageBuildings.where((b) => !b.isDead)) {
      if ((world - building.position).distance <= building.radius + 8) {
        _inspectBuilding(building);
        return;
      }
    }
    if (event.kind == PointerDeviceKind.mouse) {
      _mousePosition = event.localPosition;
      _engine.setAimDirection(world - _engine.player.position);
      if (event.buttons & kPrimaryMouseButton != 0) _mouseHeld = true;
      if (event.buttons & kSecondaryMouseButton != 0) _engine.useSpecialSkill();
    } else {
      _mousePosition = null;
      _engine.setTargetDestination(world);
    }
  }

  void _finishConstruction(bool confirm) {
    if (confirm && !_engine.confirmConstruction()) return;
    if (!confirm) _engine.cancelConstruction();
    _clearInput();
    _engine.setPaused(_pausedBeforeConstruction || !_appActive);
    _focusNode.requestFocus();
  }

  void _restart() {
    _clearInput();
    final old = _engine;
    setState(() {
      _engine = GameEngine(
        map: widget.mapModel,
        playerClass: widget.playerClass,
      );
      _lastElapsed = Duration.zero;
    });
    old.dispose();
    _focusNode.requestFocus();
  }

  void _exit() {
    _leaving = true;
    _clearInput();
    AudioEngine.startMusic('menu');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _nextLevel() {
    final next = GameMapModel.availableMaps.where(
      (map) => map.levelIndex == widget.mapModel.levelIndex + 1,
    );
    if (next.isEmpty) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VillageDefenseScreen(
          mapModel: next.first,
          playerClass: widget.playerClass,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focusNode.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_modalOpen && !_finished) _togglePause();
    },
    child: Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      onFocusChange: (focused) {
        if (focused) {
          _hadFocus = true;
          return;
        }
        _clearInput();
        if (_hadFocus && !_modalOpen && !_leaving && !_finished) {
          _engine.setPaused(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            _engine.setViewportSize(
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            return AnimatedBuilder(
              animation: _engine,
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: BattlefieldPainter(engine: _engine),
                    ),
                  ),
                  MouseRegion(
                    onHover: (event) {
                      if (_engine.pendingBuildingType != null) {
                        _engine.setBuildPreview(
                          event.localPosition + _engine.cameraOffset,
                        );
                      } else if (!_engine.isPaused && !_modalOpen) {
                        _mousePosition = event.localPosition;
                      }
                    },
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _fieldDown,
                      onPointerMove: (event) {
                        if (event.kind == PointerDeviceKind.mouse &&
                            _mouseHeld) {
                          _mousePosition = event.localPosition;
                        }
                      },
                      onPointerUp: (_) => _mouseHeld = false,
                      onPointerCancel: (_) => _mouseHeld = false,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: _engine.isPaused || _finished || _modalOpen,
                    child: GameHUD(
                      engine: _engine,
                      onShop: _showShop,
                      onPause: _togglePause,
                      onTalk: _talk,
                      onHelp: _showHelp,
                    ),
                  ),
                  if (_engine.pendingBuildingType == null)
                    IgnorePointer(
                      ignoring: _engine.isPaused || _finished || _modalOpen,
                      child: _controls(constraints),
                    ),
                  if (_engine.pendingBuildingType != null) _constructionPanel(),
                  if (_engine.isPaused &&
                      !_modalOpen &&
                      _engine.pendingBuildingType == null &&
                      !_finished)
                    _pauseOverlay(),
                  if (_finished)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: .78),
                      child: GameOverDialog(
                        engine: _engine,
                        onRestart: _restart,
                        onExit: _exit,
                        onNextLevel:
                            _engine.isVictory &&
                                widget.mapModel.levelIndex <
                                    GameMapModel.availableMaps.length
                            ? _nextLevel
                            : null,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _controls(BoxConstraints constraints) {
    final scale = SaveSystem.data.controlScale;
    final radius =
        (constraints.maxWidth * .13).clamp(36.0, 48.0) * scale.clamp(.8, 1.2);
    final leftHanded = SaveSystem.data.leftHanded;
    final player = _engine.player;
    final buttonSize = (44.0 * scale).clamp(40.0, 52.0);
    final ultimateUnlocked = player.unlockedSkillIds.any(
      (id) => id.endsWith('_ultimate'),
    );
    final move = VirtualJoystick(
      key: const Key('move-stick'),
      radius: radius,
      resetToken: _inputGeneration,
      onDirectionChanged: (direction) {
        _mousePosition = null;
        _moveDirection = direction;
        if (direction != Offset.zero) _engine.clearTargetDestination();
      },
    );
    final aim = VirtualJoystick(
      key: const Key('aim-stick'),
      radius: radius,
      label: 'APUNTAR / ATACAR',
      color: const Color(0xFFB7C5AC),
      resetToken: _inputGeneration,
      onDirectionChanged: (direction) {
        _mousePosition = null;
        _aimDirection = direction;
      },
      onActiveChanged: (active) => _aimHeld = active,
    );
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Positioned(
            left: leftHanded ? null : 12,
            right: leftHanded ? 12 : null,
            bottom: 12,
            child: move,
          ),
          Positioned(
            right: leftHanded ? null : 12,
            left: leftHanded ? 12 : null,
            bottom: 12,
            child: aim,
          ),
          Positioned(
            left: leftHanded ? 16 + radius * 2 : null,
            right: leftHanded ? null : 16 + radius * 2,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ultimateUnlocked) ...[
                  BattleActionButton(
                    label: 'Habilidad definitiva · U',
                    icon: Icons.bolt,
                    cooldown: player.ultimateSkillTimer,
                    size: buttonSize,
                    onPressed: _engine.useUltimateSkill,
                  ),
                  const SizedBox(height: 5),
                ],
                BattleActionButton(
                  label: '${widget.playerClass.specialSkillName} · E',
                  icon: heroSkillIcon(widget.playerClass.type),
                  cooldown: player.specialSkillTimer,
                  size: buttonSize,
                  onPressed: _engine.useSpecialSkill,
                ),
                const SizedBox(height: 5),
                BattleActionButton(
                  label: 'Esquivar · Mayús',
                  icon: Icons.directions_run,
                  cooldown: player.dashCooldown,
                  size: buttonSize,
                  onPressed: () => _engine.dodge(),
                ),
              ],
            ),
          ),
          if (widget.playerClass.type == PlayerRoleType.mage)
            Positioned(
              left: leftHanded ? null : 12,
              right: leftHanded ? 12 : null,
              bottom: radius * 2 + 38,
              child: BattleActionButton(
                label: 'Cambiar fuego / hielo · Q',
                icon: player.mageUsesIce
                    ? Icons.ac_unit
                    : Icons.local_fire_department,
                size: buttonSize,
                onPressed: _engine.toggleMageElement,
              ),
            ),
          if (widget.playerClass.type == PlayerRoleType.knight)
            Positioned(
              left: leftHanded ? null : 12,
              right: leftHanded ? 12 : null,
              bottom: radius * 2 + 38,
              child: Tooltip(
                message: 'Mantener para bloquear · Q',
                child: Listener(
                  onPointerDown: (_) => _engine.setBlocking(true),
                  onPointerUp: (_) => _engine.setBlocking(false),
                  onPointerCancel: (_) => _engine.setBlocking(false),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: const Color(0xEE34362A),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(Icons.shield, color: Color(0xFFC7AD79)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _constructionPanel() {
    final type = _engine.pendingBuildingType!;
    final pos = _engine.buildPreviewPosition;
    final valid = pos != null && _engine.canPlaceStructure(type, pos);
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: const Color(0xF51C211B),
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'UBICAR: ${BuildingSpec.forType(type).name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC7AD79),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      valid
                          ? 'Posición válida · ${BuildingSpec.forType(type).cost} oro'
                          : 'Toca un terreno libre cerca de la aldea',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: valid ? Colors.greenAccent : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _finishConstruction(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: valid
                                ? () => _finishConstruction(true)
                                : null,
                            child: const Text('Construir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() => ColoredBox(
    color: Colors.black.withValues(alpha: .72),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              color: const Color(0xFF1C201F),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PAUSA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC7AD79),
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La batalla está detenida.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _togglePause,
                      child: const Text('REANUDAR'),
                    ),
                    OutlinedButton(
                      onPressed: _showSettings,
                      child: const Text('AJUSTES Y CONTROLES'),
                    ),
                    TextButton(
                      onPressed: _showHelp,
                      child: const Text('CÓMO JUGAR'),
                    ),
                    TextButton(
                      onPressed: _exit,
                      child: const Text('MENÚ PRINCIPAL'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
