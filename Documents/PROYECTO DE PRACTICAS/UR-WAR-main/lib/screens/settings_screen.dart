import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/audio_engine.dart';
import '../core/save_system.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _section = 0;
  static const _actions = {
    'moveUp': 'Avanzar',
    'moveDown': 'Retroceder',
    'moveLeft': 'Izquierda',
    'moveRight': 'Derecha',
    'attack': 'Atacar',
    'special': 'Habilidad',
    'dash': 'Esquivar',
    'interact': 'Interactuar',
    'shop': 'Tienda',
    'pause': 'Pausa',
  };
  void _change(VoidCallback change) => setState(change);
  @override
  Widget build(BuildContext context) {
    final d = SaveSystem.data;
    return Scaffold(
      appBar: AppBar(title: const Text('AJUSTES & PERFIL')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'PREPARA TU EXPERIENCIA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  color: AppTheme.accentColor,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _section = i),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: _section == i
                                ? const Color(0xFF393325)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _section == i
                                  ? AppTheme.primaryColor
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            ['SONIDO', 'CONTROLES', 'PERFIL'][i],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_section == 0) ...[
                _heading('SONIDO'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Efectos de sonido'),
                  subtitle: const Text('Combate, habilidades y recompensas'),
                  value: d.soundEnabled,
                  onChanged: (v) => _change(() {
                    SaveSystem.setSoundEnabled(v);
                    if (v) AudioEngine.playCoin();
                  }),
                ),
                _slider(
                  'Volumen de efectos',
                  d.soundVolume,
                  0,
                  1,
                  (v) => _change(() => SaveSystem.setSoundVolume(v)),
                  enabled: d.soundEnabled,
                  onEnd: (_) => AudioEngine.playCoin(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Música'),
                  subtitle: const Text(
                    'Melodías originales del reino y la batalla',
                  ),
                  value: d.musicEnabled,
                  onChanged: (v) =>
                      _change(() => SaveSystem.setMusicEnabled(v)),
                ),
                _slider(
                  'Volumen de música',
                  d.musicVolume,
                  0,
                  1,
                  (v) => _change(() => SaveSystem.setMusicVolume(v)),
                  enabled: d.musicEnabled,
                ),
              ],
              if (_section == 1) ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          'EN EL CAMPO DE BATALLA',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            color: AppTheme.accentColor,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.open_with,
                                    size: 40,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(height: 8),
                                  Text('MOVER', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                            Icon(Icons.more_horiz, color: AppTheme.muted),
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 40,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'APUNTAR / ATACAR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        Text(
                          'En móvil: arrastra los controles. En escritorio: usa el teclado y apunta con el ratón. Mantén el ataque para golpear de forma continua.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _heading('CONTROLES'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ataque automático'),
                  subtitle: const Text(
                    'Ataca continuamente mientras haya enemigos a tu alcance',
                  ),
                  value: d.autoAttack,
                  onChanged: (v) => _change(() => SaveSystem.setAutoAttack(v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ayuda al apuntar'),
                  subtitle: const Text(
                    'Orienta el ataque hacia enemigos cercanos cuando no apuntas',
                  ),
                  value: d.aimAssist,
                  onChanged: (v) => _change(() => SaveSystem.setAimAssist(v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Controles para zurdos'),
                  subtitle: const Text(
                    'Intercambia movimiento y acciones táctiles',
                  ),
                  value: d.leftHanded,
                  onChanged: (v) => _change(() => SaveSystem.setLeftHanded(v)),
                ),
                _slider(
                  'Tamaño de controles',
                  d.controlScale,
                  .8,
                  1.3,
                  (v) => _change(() => SaveSystem.setControlScale(v)),
                ),
                _heading('TECLADO'),
                const Text(
                  'Selecciona una acción y pulsa su nueva tecla. Si está en uso, las dos acciones intercambian sus teclas.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final e in _actions.entries)
                      OutlinedButton(
                        onPressed: () => _remap(e.key, e.value),
                        child: Text(
                          '${e.value}: ${LogicalKeyboardKey(d.keyBindings[e.key]!).keyLabel}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _change(SaveSystem.resetKeyBindings),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar teclas originales'),
                  ),
                ),
                _heading('AYUDA'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Volver a mostrar las guías'),
                  subtitle: const Text(
                    'Reinicia la guía inicial y los consejos del nivel 1',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    SaveSystem.setTutorialSeen(false);
                    SaveSystem.resetTutorialHints();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Guías activadas para la próxima partida.',
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (_section == 2) ...[
                Center(
                  child: Column(
                    children: [
                      _heading('TU CAMPAÑA'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 28,
                            runSpacing: 18,
                            children: [
                              _stat(
                                'Récord',
                                '${d.highScore} PTS',
                                Icons.emoji_events_outlined,
                              ),
                              _stat(
                                'Enemigos',
                                '${d.totalKills}',
                                Icons.shield_outlined,
                              ),
                              _stat(
                                'Oro reunido',
                                '${d.totalGoldGathered}',
                                Icons.monetization_on_outlined,
                              ),
                              _stat(
                                'Campaña',
                                '${d.unlockedCampaignLevel} / 5',
                                Icons.flag_outlined,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (SaveSystem.lastError != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            SaveSystem.lastError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'El progreso y los ajustes se guardan en este dispositivo. Las estrellas premian la victoria y la conservación de la aldea.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppTheme.accentColor,
        fontFamily: 'Cinzel',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    ),
  );
  Widget _stat(String label, String value, IconData icon) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFC7AD79)),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    ),
  );
  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> changed, {
    bool enabled = true,
    ValueChanged<double>? onEnd,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label · ${(value * 100).round()}%',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: 10,
        label: '${(value * 100).round()}%',
        onChanged: enabled ? changed : null,
        onChangeEnd: onEnd,
      ),
    ],
  );
  Future<void> _remap(String action, String label) async {
    final key = await showDialog<int>(
      context: context,
      builder: (context) => Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) {
            Navigator.pop(context, event.logicalKey.keyId);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AlertDialog(
          title: Text('Tecla para $label'),
          content: const Text('Pulsa la tecla que deseas usar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (key != null && mounted) {
      _change(() => SaveSystem.setKeyBinding(action, key));
    }
  }
}