import 'package:flutter/material.dart';
import '../logic/game_engine.dart';

class GameOverDialog extends StatelessWidget {
  final GameEngine engine;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback? onNextLevel;
  const GameOverDialog({
    super.key,
    required this.engine,
    required this.onRestart,
    required this.onExit,
    this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final victory = engine.isVictory;
    final color = victory ? const Color(0xFFC7AD79) : const Color(0xFFC57C69);
    final minutes = engine.elapsedTime ~/ 60;
    final seconds = (engine.elapsedTime % 60).floor().toString().padLeft(
      2,
      '0',
    );
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Material(
              color: const Color(0xFF1C201F),
              borderRadius: BorderRadius.circular(5),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      victory ? Icons.emoji_events : Icons.shield_outlined,
                      color: color,
                      size: 42,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'RESULTADOS DE BATALLA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Cinzel',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      victory ? '¡VICTORIA!' : 'LA DEFENSA HA CAÍDO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 23,
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      engine.resultRank,
                      style: TextStyle(
                        color: color.withValues(alpha: .9),
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (victory) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              index < engine.resultStars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: index < engine.resultStars
                                  ? const Color(0xFFFFD166)
                                  : Colors.white24,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      victory
                          ? 'Objetivos completados. Tu progreso se ha guardado.'
                          : engine.player.health <= 0
                          ? 'Tu héroe cayó en combate. Refuerza tus defensas e inténtalo otra vez.'
                          : 'El corazón de la aldea fue destruido. Repara y protege sus accesos.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          _stat('Duración', '$minutes:$seconds'),
                          _stat(
                            'Oleadas completadas',
                            '${engine.completedWaves}/${engine.map.totalWaves}',
                          ),
                          _stat(
                            'Integridad de la aldea',
                            '${(engine.villageIntegrity * 100).round()}%',
                          ),
                          _stat(
                            'Enemigos eliminados',
                            '${engine.player.kills}',
                          ),
                          _stat('Jefes derrotados', '${engine.bossesDefeated}'),
                          _stat(
                            'Daño causado',
                            '${engine.damageDealt.round()}',
                          ),
                          _stat(
                            'Daño recibido',
                            '${engine.damageTaken.round()}',
                          ),
                          _stat(
                            'Edificios perdidos',
                            '${engine.buildingsLost}',
                          ),
                          _stat(
                            'Enemigos resucitados',
                            '${engine.enemiesRevived}',
                          ),
                          _stat(
                            'Campamentos destruidos',
                            '${engine.rivalCamps.where((c) => c.isDestroyed).length}/${engine.rivalCamps.length}',
                          ),
                          _stat('Oro disponible', '${engine.player.gold}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          color: Color(0xFFFFD166),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'PUNTUACIÓN  ${engine.player.score}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cinzel',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (victory && onNextLevel != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onNextLevel,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('SIGUIENTE NIVEL'),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onRestart,
                        child: Text(victory ? 'VOLVER A JUGAR' : 'REINTENTAR'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onExit,
                        child: const Text('MENÚ PRINCIPAL'),
                      ),
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

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
