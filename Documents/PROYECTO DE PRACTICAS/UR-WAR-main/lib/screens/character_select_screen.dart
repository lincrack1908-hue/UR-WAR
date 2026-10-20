import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/realm_widgets.dart';
import '../game/models/player_class.dart';
import 'map_select_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});
  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  int _selectedIndex = 0;
  static const _names = ['Caballero', 'Cazadora', 'Mago', 'Guardiana'];
  @override
  Widget build(BuildContext context) {
    final hero = PlayerClass.availableClasses[_selectedIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('ELIGE A TU GUARDIÁN')),
      body: RealmBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > 680;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Semantics(
                                selected: i == _selectedIndex,
                                button: true,
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedIndex = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i == _selectedIndex
                                          ? const Color(0xFF393325)
                                          : AppTheme.surfaceColor,
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 2,
                                          color: i == _selectedIndex
                                              ? AppTheme.primaryColor
                                              : Colors.white12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _names[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: i == _selectedIndex
                                            ? AppTheme.accentColor
                                            : AppTheme.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _portrait(hero)),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: _details(hero),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: box.maxHeight < 600 ? 270 : 350,
                                  child: _portrait(hero),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: _details(hero),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.outlined_flag),
                        label: const Text('CONTINUAR: ELEGIR MAPA'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MapSelectScreen(selectedClass: hero),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _portrait(PlayerClass hero) => Stack(
    fit: StackFit.expand,
    children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: SizedBox.expand(
          key: ValueKey(_selectedIndex),
          child: AtlasArt(
            asset: 'assets/images/heroes_atlas.png',
            index: _selectedIndex,
            count: 4,
            panelAspect: .625,
            verticalAlignment: -1,
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              AppTheme.darkBackground,
            ],
            stops: [0, .65, 1],
          ),
        ),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 16,
        child: Column(
          children: [
            Text(
              'GUARDIÁN 0${_selectedIndex + 1}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 9,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hero.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 24,
                color: AppTheme.ivory,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _details(PlayerClass hero) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        hero.roleTitle.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accentColor,
          letterSpacing: 1,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        hero.description,
        style: const TextStyle(
          color: AppTheme.muted,
          height: 1.6,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: _stat(
              'VITALIDAD',
              '${hero.maxHealth.toInt()}',
              Icons.favorite_outline,
            ),
          ),
          Expanded(
            child: _stat(
              'DAÑO',
              '${hero.baseDamage.toInt()}',
              Icons.gavel_outlined,
            ),
          ),
          Expanded(
            child: _stat('VELOCIDAD', '${hero.moveSpeed.toInt()}', Icons.air),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Divider(),
      ),
      Text(
        hero.specialSkillName,
        style: const TextStyle(
          fontFamily: 'Cinzel',
          color: AppTheme.accentColor,
          fontSize: 17,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        hero.specialSkillDescription,
        style: const TextStyle(
          color: AppTheme.muted,
          height: 1.5,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'ESTILO DE COMBATE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.primaryColor,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      Text(switch (hero.type) {
        PlayerRoleType.knight =>
          'Mantén el escudo hacia la amenaza. Esquiva, cierra la distancia y domina el frente.',
        PlayerRoleType.ranger =>
          'Apunta desde lejos. Esquiva para dejar una trampa y mantener a las hordas a distancia.',
        PlayerRoleType.mage =>
          'Alterna fuego y hielo. Concentra a los enemigos antes de lanzar tu magia de área.',
        PlayerRoleType.cleric =>
          'Protege a tu aldea con un santuario. Alterna golpes de bastón y curación.',
      }, style: const TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.5)),
    ],
  );
  Widget _stat(String name, String value, IconData icon) => Column(
    children: [
      Icon(icon, size: 19, color: AppTheme.primaryColor),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 23,
          color: AppTheme.ivory,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        name,
        style: const TextStyle(
          fontSize: 8,
          letterSpacing: 1,
          color: AppTheme.muted,
        ),
      ),
    ],
  );
}
