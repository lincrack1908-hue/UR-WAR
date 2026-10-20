import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/audio_engine.dart';
import '../core/constants.dart';
import '../core/save_system.dart';
import 'character_select_screen.dart';
import 'credits_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'tetris_screen.dart';

const _gold = Color(0xFFC7AD79);
const _ivory = Color(0xFFF0E9DC);
const _muted = Color(0xFFABA99F);
const _ink = Color(0xFF090D0E);

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Future<void> _open(Widget screen) async {
    AudioEngine.startMusic();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      AudioEngine.startMusic();
      setState(() {});
    }
  }

  Widget _brand(bool wide) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const _Eyebrow('CRÓNICAS DEL REINO'),
      const SizedBox(height: 10),
      Text(
        AppConstants.appName,
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: wide ? 70 : 58,
          height: 1,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
          color: _ivory,
          shadows: const [Shadow(color: Colors.black, blurRadius: 24)],
        ),
      ),
      const SizedBox(height: 14),
      const SizedBox(width: 220, child: _CrestRule()),
      const SizedBox(height: 14),
      const Text(
        'Defiende. Explora. Reconquista.',
        style: TextStyle(color: _gold, fontSize: 12, letterSpacing: .6),
      ),
    ],
  );

  Widget _menu() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('TU PRÓXIMA BATALLA'),
      const SizedBox(height: 12),
      _MenuEntry(
        number: 'I',
        label: 'JUGAR',
        subtitle: 'Defiende la aldea · Campaña',
        primary: true,
        onTap: () => _open(const CharacterSelectScreen()),
      ),
      const SizedBox(height: 8),
      _MenuEntry(
        number: 'II',
        label: 'ARENA TÁCTICA',
        subtitle: 'Estrategia por turnos',
        onTap: () => _open(const GameScreen()),
      ),
      _MenuEntry(
        number: 'III',
        label: 'TABERNA & ENTRENAMIENTO',
        subtitle: 'Minijuego de Bloques & 4 Poderes Rúnicos',
        onTap: () => _open(const TetrisScreen()),
      ),
      _MenuEntry(
        number: 'IV',
        label: 'AJUSTES',
        onTap: () => _open(const SettingsScreen()),
      ),
      _MenuEntry(
        number: 'V',
        label: 'CRÉDITOS & OPEN SOURCE',
        onTap: () => _open(const CreditsScreen()),
      ),
    ],
  );

  Widget _progress() {
    final data = SaveSystem.data;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stat(
          value:
              '${data.unlockedCampaignLevel.toString().padLeft(2, '0')} / 05',
          label: 'CAMPAÑA',
          icon: Icons.outlined_flag,
        ),
        Container(
          height: 28,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          color: _gold.withValues(alpha: .25),
        ),
        _Stat(
          value: '${data.highScore}',
          label: 'RÉCORD',
          icon: Icons.workspace_premium_outlined,
        ),
      ],
    );
  }

  Widget _footer() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 1, color: _gold.withValues(alpha: .2)),
      const SizedBox(height: 14),
      const Row(
        children: [
          Icon(Icons.check_circle_outline, size: 13, color: _muted),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Progreso guardado en este dispositivo',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ),
          Text(
            'v${AppConstants.appVersion}',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
      if (SaveSystem.lastError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            SaveSystem.lastError!,
            style: const TextStyle(color: Colors.amber, fontSize: 11),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/images/kingdom_menu.png',
                  fit: BoxFit.cover,
                  alignment: wide ? Alignment.center : const Alignment(.7, -1),
                  errorBuilder: (_, error, stack) =>
                      const ColoredBox(color: _ink),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: wide
                      ? const LinearGradient(
                          colors: [
                            Color(0xF5090D0E),
                            Color(0xD9090D0E),
                            Color(0x10090D0E),
                          ],
                          stops: [0, .32, .8],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x65090D0E),
                            Color(0x30090D0E),
                            Color(0xF5090D0E),
                            _ink,
                          ],
                          stops: [0, .23, .55, 1],
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .7),
                    ],
                    stops: const [0, .55, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: wide
                  ? _wideLayout(constraints)
                  : _mobileLayout(constraints),
            ),
          ],
        );
      },
    ),
  );

  Widget _mobileLayout(BoxConstraints constraints) => LayoutBuilder(
    builder: (context, safe) {
      final inset = constraints.maxWidth < 360 ? 24.0 : 32.0;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: safe.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              safe.maxHeight > 650 ? 64 : 38,
              inset,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _brand(false),
                SizedBox(height: math.max(90, safe.maxHeight * .17)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _progress(),
                    const SizedBox(height: 26),
                    _menu(),
                    const SizedBox(height: 28),
                    _footer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _wideLayout(BoxConstraints constraints) => Row(
    children: [
      Container(
        width: 410,
        margin: EdgeInsets.only(left: constraints.maxWidth > 1100 ? 64 : 32),
        padding: const EdgeInsets.only(right: 40),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: _gold.withValues(alpha: .14)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, safe) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: safe.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _brand(true),
                    const SizedBox(height: 38),
                    _menu(),
                    const SizedBox(height: 32),
                    _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _progress(),
              const Spacer(),
              const _Eyebrow('CUATRO HÉROES. UN SOLO REINO.'),
              const SizedBox(height: 10),
              const Text(
                'La última luz\ndel valle.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 36,
                  height: 1.1,
                  color: _ivory,
                  shadows: [Shadow(color: Colors.black, blurRadius: 14)],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cinco territorios esperan a sus guardianes.',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _gold,
      fontSize: 9,
      letterSpacing: 2.5,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _CrestRule extends StatelessWidget {
  const _CrestRule();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: Color(0xFF766646), height: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF8F3933),
              border: Border.all(color: _gold),
            ),
          ),
        ),
      ),
      const Expanded(child: Divider(color: Color(0xFF766646), height: 1)),
    ],
  );
}

class _Stat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _gold, size: 21),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ivory,
              fontSize: 15,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ],
  );
}

class _MenuEntry extends StatefulWidget {
  final String number, label;
  final String? subtitle;
  final bool primary;
  final VoidCallback onTap;
  const _MenuEntry({
    required this.number,
    required this.label,
    this.subtitle,
    this.primary = false,
    required this.onTap,
  });
  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
  bool _hovered = false;
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.primary || _hovered || _focused;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _focused = value),
          splashColor: _gold.withValues(alpha: .14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 50),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: widget.subtitle == null ? 16 : 17,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? [const Color(0x554F422C), const Color(0x085E5135)]
                    : [Colors.transparent, Colors.transparent],
              ),
              border: Border(
                left: BorderSide(
                  color: active ? _gold : Colors.transparent,
                  width: 2,
                ),
                top: BorderSide(
                  color: active
                      ? _gold.withValues(alpha: .35)
                      : Colors.transparent,
                ),
                bottom: BorderSide(
                  color: active
                      ? _gold.withValues(alpha: .35)
                      : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    widget.number,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 12,
                      color: active ? _gold : const Color(0xFF787970),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: active ? _ivory : const Color(0xFFCFCEC6),
                          fontSize: widget.primary ? 18 : 13,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            widget.subtitle!,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  color: active ? _gold : const Color(0xFF62655F),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
