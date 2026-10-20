import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/player_class.dart';
import '../models/tutorial_hint.dart';
import 'battle_minimap.dart';

/// Readable status and utilities. Input and modal lifetimes belong to the screen.
class GameHUD extends StatelessWidget {
  final GameEngine engine;
  final VoidCallback? onShop;
  final VoidCallback? onPause;
  final VoidCallback? onTalk;
  final VoidCallback? onHelp;
  final ValueChanged<Offset>? onJoystickDirection;

  const GameHUD({
    super.key,
    required this.engine,
    this.onShop,
    this.onPause,
    this.onTalk,
    this.onHelp,
    this.onJoystickDirection,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: engine,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 500;
        final player = engine.player;
        final wave = engine.waveSystem;
        final canTalk = engine.npcs.any(
          (npc) => (npc.position - player.position).distance <= 90,
        );
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 8,
                right: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: _panel,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HÉROE · NIVEL ${player.level}',
                                  style: _label,
                                ),
                                _bar(
                                  player.health / player.maxHealth,
                                  const Color(0xFF93B58B),
                                  '${player.health.ceil()}/${player.maxHealth.ceil()}',
                                ),
                                const SizedBox(height: 3),
                                LinearProgressIndicator(
                                  value: (player.xp / player.xpToNextLevel)
                                      .clamp(0, 1),
                                  color: const Color(0xFFB9AA80),
                                  minHeight: 3,
                                  backgroundColor: Colors.white12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CORAZÓN DE LA ALDEA',
                                  style: _label,
                                ),
                                _bar(
                                  engine.townHall.health /
                                      engine.townHall.maxHealth,
                                  const Color(0xFFB9AA80),
                                  '${engine.townHall.health.ceil()}/${engine.townHall.maxHealth.ceil()}',
                                ),
                                Text(
                                  'OLEADA ${wave.currentWave}/${wave.maxWaves} · ${player.gold} oro',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFC7AD79),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Pausar',
                            onPressed: onPause,
                            icon: const Icon(
                              Icons.pause_circle_filled,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: _panel,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  engine.objectiveText,
                                  maxLines: compact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                                if (!wave.isWaveInProgress &&
                                    engine.completedWaves < wave.maxWaves) ...[
                                  if (!compact)
                                    Text(
                                      wave.nextWaveSummary,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: 34,
                                    child: FilledButton.icon(
                                      key: const Key('start-wave'),
                                      onPressed: engine.startNextWave,
                                      icon: const Icon(
                                        Icons.play_arrow,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'Iniciar oleada',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BattleMinimap(engine: engine, width: compact ? 82 : 94),
                      ],
                    ),
                    if (engine.announcementBanner != null && !compact)
                      IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE62D3027),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            engine.announcementBanner!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC7AD79),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: compact ? 166 : 222,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _utility(
                      'Tienda y habilidades',
                      Icons.storefront,
                      onShop,
                      badge: player.skillPoints > 0
                          ? '${player.skillPoints}'
                          : null,
                    ),
                    if (canTalk)
                      _utility('Hablar', Icons.chat_bubble_outline, onTalk),
                    if (!compact)
                      _utility('Ayuda y controles', Icons.help_outline, onHelp),
                  ],
                ),
              ),
              if (engine.activeTutorialHint != null)
                Positioned(
                  left: 12,
                  right: compact ? 64 : 96,
                  bottom: compact ? 108 : 132,
                  child: TutorialHintPanel(
                    hint: engine.activeTutorialHint!,
                    compact: compact,
                    onDismiss: engine.dismissTutorialHint,
                    onDisable: engine.disableTutorialHints,
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  static const _label = TextStyle(
    color: Colors.white70,
    fontSize: 9,
    fontWeight: FontWeight.bold,
  );
  static final _panel = BoxDecoration(
    color: const Color(0xEA171C18),
    borderRadius: BorderRadius.circular(9),
    border: Border.all(color: const Color(0xFF6D6249)),
  );

  Widget _bar(double value, Color color, String text) => Stack(
    alignment: Alignment.center,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          color: color.withValues(alpha: .65),
          backgroundColor: Colors.black38,
          minHeight: 16,
        ),
      ),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _utility(
    String label,
    IconData icon,
    VoidCallback? action, {
    String? badge,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Tooltip(
      message: label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xEE2B3025),
          ),
          onPressed: action,
          child: Badge(
            isLabelVisible: badge != null,
            label: Text(badge ?? ''),
            child: Icon(icon, color: const Color(0xFFC7AD79), size: 22),
          ),
        ),
      ),
    ),
  );
}

class TutorialHintPanel extends StatelessWidget {
  final TutorialHint hint;
  final bool compact;
  final VoidCallback onDismiss;
  final VoidCallback onDisable;

  const TutorialHintPanel({
    super.key,
    required this.hint,
    required this.compact,
    required this.onDismiss,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${hint.title}. ${hint.message}',
    child: Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: EdgeInsets.all(compact ? 8 : 11),
        decoration: BoxDecoration(
          color: const Color(0xF21A211C),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFC7AD79), width: 1.2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hint.icon,
              color: const Color(0xFFC7AD79),
              size: compact ? 22 : 27,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hint.title,
                    style: TextStyle(
                      color: const Color(0xFFC7AD79),
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hint.message,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 10 : 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      SizedBox(
                        height: 28,
                        child: FilledButton(
                          key: const Key('tutorial-hint-dismiss'),
                          onPressed: onDismiss,
                          child: const Text(
                            'Entendido',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 28,
                        child: TextButton(
                          key: const Key('tutorial-hint-disable'),
                          onPressed: onDisable,
                          child: const Text(
                            'No mostrar más',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BattleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double cooldown;
  final VoidCallback onPressed;
  final double size;
  const BattleActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.cooldown = 0,
    this.size = 48,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xEF303329),
          disabledBackgroundColor: const Color(0xE6191E19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.white30),
          ),
        ),
        onPressed: cooldown <= 0 ? onPressed : null,
        child: cooldown > 0
            ? Text(
                '${cooldown.ceil()}',
                style: const TextStyle(color: Colors.white70),
              )
            : Icon(icon, color: const Color(0xFFC7AD79), size: 23),
      ),
    ),
  );
}

IconData heroSkillIcon(PlayerRoleType type) => switch (type) {
  PlayerRoleType.knight => Icons.cyclone,
  PlayerRoleType.ranger => Icons.filter_center_focus,
  PlayerRoleType.mage => Icons.auto_awesome,
  PlayerRoleType.cleric => Icons.health_and_safety,
};
