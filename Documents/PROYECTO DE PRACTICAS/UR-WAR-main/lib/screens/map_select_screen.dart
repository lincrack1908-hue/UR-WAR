import 'package:flutter/material.dart';
import '../core/save_system.dart';
import '../core/theme.dart';
import '../core/realm_widgets.dart';
import '../game/models/game_map.dart';
import '../game/models/player_class.dart';
import 'village_defense_screen.dart';

class MapSelectScreen extends StatefulWidget {
  final PlayerClass selectedClass;
  const MapSelectScreen({super.key, required this.selectedClass});
  @override
  State<MapSelectScreen> createState() => _MapSelectScreenState();
}

class _MapSelectScreenState extends State<MapSelectScreen> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final maps = GameMapModel.availableMaps;
    final selected = maps[_selectedIndex];
    final unlocked = SaveSystem.isLevelUnlocked(selected.levelIndex);
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'ELIGE TU TERRITORIO',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    '${widget.selectedClass.name} · Campaña ${SaveSystem.data.unlockedCampaignLevel}/5',
                    style: const TextStyle(color: AppTheme.accentColor),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Text(
                    '★ Victoria   ★★ Aldea ≥50%   ★★★ Aldea ≥80%',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFFE7CC8D)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: maps.length,
                    itemBuilder: (context, index) {
                      final map = maps[index];
                      final locked = !SaveSystem.isLevelUnlocked(
                        map.levelIndex,
                      );
                      final chosen = _selectedIndex == index;
                      final stars = SaveSystem.starsFor(map.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: chosen
                              ? const Color(0xFF343026)
                              : AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              color: chosen
                                  ? const Color(0xFFE7CC8D)
                                  : Colors.white12,
                              width: chosen ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => _selectedIndex = index),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 175,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AtlasArt(
                                        asset:
                                            'assets/images/territories_atlas.png',
                                        index: map.biome.index,
                                        count: 3,
                                        panelAspect: 1,
                                      ),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0xC0090D0E),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 16,
                                        bottom: 14,
                                        child: Text(
                                          'TERRITORIO 0${map.levelIndex}',
                                          style: const TextStyle(
                                            fontFamily: 'Cinzel',
                                            color: AppTheme.accentColor,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              map.name,
                                              style: const TextStyle(
                                                fontFamily: 'Cinzel',
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            locked
                                                ? Icons.lock_outline
                                                : chosen
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: locked
                                                ? Colors.white38
                                                : const Color(0xFFE7CC8D),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        map.subtitle,
                                        style: const TextStyle(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        map.description,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            '${map.totalWaves} oleadas',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            '${map.rivalCamps.length} campamentos',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            map.difficultyText,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFE7CC8D),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              3,
                                              (i) => Icon(
                                                i < stars
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                size: 18,
                                                color: const Color(0xFFE7CC8D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (locked)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Text(
                                            'Completa el nivel ${map.levelIndex - 1} para desbloquearlo.',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if ((SaveSystem.data.levelScores[map
                                                  .id] ??
                                              0) >
                                          0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Mejor puntuación: ${SaveSystem.data.levelScores[map.id]}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: unlocked
                          ? () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VillageDefenseScreen(
                                  mapModel: selected,
                                  playerClass: widget.selectedClass,
                                ),
                              ),
                            )
                          : null,
                      icon: Icon(
                        unlocked ? Icons.shield_rounded : Icons.lock_outline,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          unlocked
                              ? '¡COMENZAR DEFENSA DE LA ALDEA!'
                              : 'TERRITORIO BLOQUEADO',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The preview uses actual obstacle and camp coordinates, including every biome.
