import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio_engine.dart';
import '../core/theme.dart';
import '../game/tetris/tetris_engine.dart';
import '../game/tetris/tetris_models.dart';
import '../game/tetris/tetris_painter.dart';

/// Pantalla del modo "Tetris con poderes".
/// Tablero, controles (teclado y táctiles), HUD, poderes, pausa y game over.
class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen>
    with SingleTickerProviderStateMixin {
  final TetrisEngine _engine = TetrisEngine();
  final PowerFx _fx = PowerFx();
  final FocusNode _focusNode = FocusNode();
  late final Ticker _ticker;

  Duration _lastElapsed = Duration.zero;
  int _lastClearId = 0;
  int _lastPowerEventId = 0;
  int _lastLevel = 1;
  GameStatus _lastStatus = GameStatus.ready;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineChanged);
    _engine.start();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _fx.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------- lógica

  void _onTick(Duration elapsed) {
    final dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    _engine.tick(dt);
    _fx.advance(dt.inMicroseconds / 1000.0);
  }

  /// Sonidos y efectos según lo que pase en el motor.
  void _onEngineChanged() {
    if (_engine.clearEventId != _lastClearId) {
      _lastClearId = _engine.clearEventId;
      AudioEngine.playCoin();
    }
    if (_engine.powerEventId != _lastPowerEventId) {
      _lastPowerEventId = _engine.powerEventId;
      final event = _engine.lastPowerEvent;
      if (event != null) {
        _fx.start(event);
      }
      AudioEngine.playSpecialSkill();
    }
    if (_engine.level != _lastLevel) {
      if (_engine.level > _lastLevel) {
        AudioEngine.playLevelUp();
      }
      _lastLevel = _engine.level;
    }
    if (_engine.status != _lastStatus) {
      if (_engine.status == GameStatus.gameOver) {
        AudioEngine.playDefeat();
      }
      _lastStatus = _engine.status;
    }
  }

  void _togglePause() {
    if (_engine.status == GameStatus.playing) {
      _engine.pause();
    } else if (_engine.status == GameStatus.paused) {
      _engine.resume();
    }
    _focusNode.requestFocus();
  }

  void _restart() {
    _engine.start();
    _focusNode.requestFocus();
  }

  void _exit() {
    Navigator.of(context).pop();
  }

  void _choosePower(PowerType type) {
    _engine.choosePower(type);
    _focusNode.requestFocus();
  }

  void _usePower(PowerType type) {
    _engine.usePower(type);
    _focusNode.requestFocus();
  }

  void _confirmTarget() {
    final ok = _engine.confirmTarget();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No hay bloques en esa zona. Elige otra.'),
            duration: Duration(seconds: 1),
          ),
        );
    }
    _focusNode.requestFocus();
  }

  void _cancelTarget() {
    _engine.cancelTarget();
    _focusNode.requestFocus();
  }

  void _targetFromPointer(Offset local, Size size) {
    if (_engine.status != GameStatus.targeting) {
      return;
    }
    final (row, col) = TetrisGeometry.of(size).cellAt(local);
    _engine.setTarget(row, col);
  }

  PowerType? _powerForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      return PowerType.lightning;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      return PowerType.bomb;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      return PowerType.freeze;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      return PowerType.divine;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final isRepeat = event is KeyRepeatEvent;
    final status = _engine.status;

    // Pantalla de elegir poder: solo teclas 1-4.
    if (status == GameStatus.choosingPower) {
      final power = _powerForKey(key);
      if (power != null && !isRepeat) {
        _choosePower(power);
      }
      return KeyEventResult.handled;
    }

    // Elegir fila o zona del poder.
    if (status == GameStatus.targeting) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        _engine.moveTarget(-1, 0);
      } else if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        _engine.moveTarget(1, 0);
      } else if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        _engine.moveTarget(0, -1);
      } else if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        _engine.moveTarget(0, 1);
      } else if (!isRepeat &&
          (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space)) {
        _confirmTarget();
      } else if (!isRepeat &&
          (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP)) {
        _cancelTarget();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.escape) {
      if (!isRepeat) {
        _togglePause();
      }
      return KeyEventResult.handled;
    }

    if (status == GameStatus.gameOver) {
      if (key == LogicalKeyboardKey.enter && !isRepeat) {
        _restart();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // ATAJO DE PRUEBA: L sube 5 niveles (bórralo al terminar).
    if (key == LogicalKeyboardKey.keyL) {
      if (!isRepeat) {
        _engine.debugLevelUp(5);
      }
      return KeyEventResult.handled;
    }

    // Poderes 1-4.
    final power = _powerForKey(key);
    if (power != null) {
      if (!isRepeat) {
        _engine.usePower(power);
      }
      return KeyEventResult.handled;
    }

    // Estas teclas se repiten al mantenerlas apretadas.
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _engine.moveLeft();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _engine.moveRight();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _engine.softDrop();
      return KeyEventResult.handled;
    }

    // Estas solo cuentan al presionar (no al mantener).
    if (isRepeat) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyX ||
        key == LogicalKeyboardKey.keyW) {
      _engine.rotateClockwise();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyZ) {
      _engine.rotateCounterClockwise();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _engine.hardDrop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'TETRIS CON PODERES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _engine,
            builder: (context, _) {
              final paused = _engine.status == GameStatus.paused;
              final canToggle = paused || _engine.status == GameStatus.playing;
              return IconButton(
                tooltip: paused ? 'Continuar' : 'Pausar',
                onPressed: canToggle ? _togglePause : null,
                icon: Icon(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _onKey,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  return wide ? _buildWide() : _buildNarrow();
                },
              ),
            ),
          ),
          // Pantalla especial para canjear el punto de habilidad.
          ListenableBuilder(
            listenable: _engine,
            builder: (context, _) {
              if (_engine.status != GameStatus.choosingPower) {
                return const SizedBox.shrink();
              }
              return _PowerChoiceOverlay(
                engine: _engine,
                onChoose: _choosePower,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Pantallas angostas (móvil): estadísticas arriba, tablero y controles abajo.
  Widget _buildNarrow() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: _buildStatsRow(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: _buildBoard()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: ListenableBuilder(
            listenable: _engine,
            builder: (context, _) {
              if (_engine.status == GameStatus.targeting) {
                return _buildTargetingBar();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPowerBar(),
                  const SizedBox(height: 8),
                  _buildControls(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Pantallas anchas (PC / web): tablero al centro y panel a la derecha.
  Widget _buildWide() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Center(child: _buildBoard())),
          const SizedBox(width: 24),
          SizedBox(
            width: 270,
            child: SingleChildScrollView(child: _buildSidePanel()),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: TetrisConfig.columns / TetrisConfig.rows,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _targetFromPointer(d.localPosition, size),
                onPanUpdate: (d) => _targetFromPointer(d.localPosition, size),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: TetrisBoardPainter(_engine)),
                    IgnorePointer(
                      child: CustomPaint(painter: PowerFxPainter(_fx)),
                    ),
                    ListenableBuilder(
                      listenable: _engine,
                      builder: (context, _) =>
                          _buildOverlay() ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildOverlay() {
    switch (_engine.status) {
      case GameStatus.paused:
        return _Overlay(
          title: 'PAUSA',
          lines: const [],
          actions: [
            _OverlayButton(
              label: 'CONTINUAR',
              primary: true,
              onPressed: _togglePause,
            ),
            _OverlayButton(label: 'REINICIAR', onPressed: _restart),
            _OverlayButton(label: 'SALIR AL MENÚ', onPressed: _exit),
          ],
        );
      case GameStatus.gameOver:
        return _Overlay(
          title: 'GAME OVER',
          lines: [
            'Puntaje: ${_engine.score}',
            'Nivel máximo: ${_engine.level}',
            'Líneas: ${_engine.lines}',
          ],
          actions: [
            _OverlayButton(
              label: 'JUGAR DE NUEVO',
              primary: true,
              onPressed: _restart,
            ),
            _OverlayButton(label: 'SALIR AL MENÚ', onPressed: _exit),
          ],
        );
      case GameStatus.ready:
      case GameStatus.playing:
      case GameStatus.choosingPower:
      case GameStatus.targeting:
        return null;
    }
  }

  Widget _buildStatsRow() {
    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _StatCard(label: 'PUNTOS', value: '${_engine.score}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _StatCard(
                label: 'NIVEL',
                value: _engine.isInfinite
                    ? '${_engine.level} ∞'
                    : '${_engine.level}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _StatCard(label: 'LÍNEAS', value: '${_engine.lines}'),
            ),
            const SizedBox(width: 8),
            _NextBox(engine: _engine, size: 64),
          ],
        );
      },
    );
  }

  Widget _buildSidePanel() {
    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        final targeting = _engine.status == GameStatus.targeting;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SIGUIENTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: _NextBox(engine: _engine, size: 96)),
            const SizedBox(height: 16),
            _StatCard(label: 'PUNTOS', value: '${_engine.score}'),
            const SizedBox(height: 10),
            _StatCard(
              label: 'NIVEL',
              value: '${_engine.level}',
              caption: _engine.isInfinite
                  ? 'MODO INFINITO'
                  : 'Siguiente nivel en ${_engine.linesToNextLevel} líneas',
            ),
            const SizedBox(height: 10),
            _StatCard(label: 'LÍNEAS', value: '${_engine.lines}'),
            const SizedBox(height: 16),
            const Text(
              'PODERES',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            _buildPowerGrid(),
            const SizedBox(height: 12),
            if (targeting) _buildTargetingBar() else const _ControlsHelp(),
          ],
        );
      },
    );
  }

  /// Texto mientras un poder está activo (el Congelamiento dura 6 s).
  String? _activeLabel(PowerType type) {
    if (type == PowerType.freeze && _engine.isFrozen) {
      return '${(_engine.freezeRemainingMs / 1000).ceil()} s';
    }
    return null;
  }

  Widget _powerButton(PowerType type, {required bool showName}) {
    return _PowerButton(
      power: type,
      unlocked: _engine.isUnlocked(type),
      cooldownMs: _engine.cooldownRemainingMs(type),
      hotkey: type.index + 1,
      activeLabel: _activeLabel(type),
      showName: showName,
      onPressed: () => _usePower(type),
    );
  }

  /// Fila de 4 poderes (móvil).
  Widget _buildPowerBar() {
    return Row(
      children: [
        for (var i = 0; i < PowerType.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _powerButton(PowerType.values[i], showName: false)),
        ],
      ],
    );
  }

  /// Cuadrícula 2x2 de poderes (PC).
  Widget _buildPowerGrid() {
    const types = PowerType.values;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _powerButton(types[0], showName: true)),
            const SizedBox(width: 8),
            Expanded(child: _powerButton(types[1], showName: true)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _powerButton(types[2], showName: true)),
            const SizedBox(width: 8),
            Expanded(child: _powerButton(types[3], showName: true)),
          ],
        ),
      ],
    );
  }

  /// Barra con confirmar / cancelar mientras se elige la fila o la zona.
  Widget _buildTargetingBar() {
    final isLightning = _engine.targetPower == PowerType.lightning;
    final title = isLightning
        ? '⚡ Elige la fila a desintegrar'
        : '💣 Elige el centro de la explosión';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Toca el tablero o usa las flechas',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelTarget,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('CANCELAR'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmTarget,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('CONFIRMAR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(64.0, (constraints.maxWidth - 32) / 5);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ControlButton(
                  icon: Icons.chevron_left_rounded,
                  size: size,
                  repeat: true,
                  onPressed: _engine.moveLeft,
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  size: size,
                  repeat: true,
                  onPressed: _engine.softDrop,
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.chevron_right_rounded,
                  size: size,
                  repeat: true,
                  onPressed: _engine.moveRight,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ControlButton(
                  icon: Icons.rotate_right_rounded,
                  size: size,
                  onPressed: _engine.rotateClockwise,
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.vertical_align_bottom_rounded,
                  size: size,
                  color: AppTheme.primaryColor,
                  onPressed: _engine.hardDrop,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// =================================================================
// Widgets auxiliares
// =================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _NextBox extends StatelessWidget {
  const _NextBox({required this.engine, required this.size});

  final TetrisEngine engine;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: CustomPaint(painter: NextPiecePainter(engine)),
    );
  }
}

class _ControlsHelp extends StatelessWidget {
  const _ControlsHelp();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white60, fontSize: 12, height: 1.5);
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTROLES',
          style: TextStyle(
            color: AppTheme.accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 6),
        Text('← → / A D  Mover', style: style),
        Text('↑ / X / W  Rotar', style: style),
        Text('Z  Rotar al revés', style: style),
        Text('↓ / S  Bajar', style: style),
        Text('Espacio  Caída instantánea', style: style),
        Text('1 2 3 4  Usar poder', style: style),
        Text('P / Esc  Pausa', style: style),
      ],
    );
  }
}

/// Botón de un poder: icono, estado (bloqueado / recargando / LISTO) y
/// (en PC) tecla y nombre. Usa eventos de puntero para no robarle el foco
/// al teclado.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.power,
    required this.unlocked,
    required this.cooldownMs,
    required this.hotkey,
    required this.onPressed,
    this.activeLabel,
    this.showName = false,
  });

  final PowerType power;
  final bool unlocked;
  final double cooldownMs;
  final int hotkey;
  final VoidCallback onPressed;
  final String? activeLabel;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final ready = unlocked && cooldownMs <= 0;
    final cooling = unlocked && cooldownMs > 0;
    final active = activeLabel != null;

    final String status;
    if (!unlocked) {
      status = 'Bloqueado';
    } else if (active) {
      status = activeLabel!;
    } else if (cooling) {
      status = '${(cooldownMs / 1000).ceil()} s';
    } else {
      status = 'LISTO';
    }

    final double progress = cooling
        ? (1 - cooldownMs / TetrisConfig.powerCooldownMs)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return Listener(
      onPointerDown: ready ? (_) => onPressed() : null,
      child: Opacity(
        opacity: !unlocked ? 0.35 : (cooling && !active ? 0.6 : 1),
        child: Container(
          height: showName ? 78 : 56,
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0E7490).withValues(alpha: 0.6)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ready
                  ? const Color(0xFFFDE047).withValues(alpha: 0.8)
                  : Colors.white12,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                unlocked ? power.icon : '🔒',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                status,
                style: TextStyle(
                  color: ready ? const Color(0xFFFDE047) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (cooling && !active)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              if (showName)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$hotkey · ${power.displayName}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla especial: canjear un punto de habilidad por un poder.
class _PowerChoiceOverlay extends StatelessWidget {
  const _PowerChoiceOverlay({required this.engine, required this.onChoose});

  final TetrisEngine engine;
  final void Function(PowerType) onChoose;

  @override
  Widget build(BuildContext context) {
    final points = engine.pendingSkillPoints;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡NIVEL ${engine.level}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: AppTheme.primaryColor, blurRadius: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    points == 1
                        ? '+1 PUNTO DE HABILIDAD'
                        : '$points PUNTOS DE HABILIDAD',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Desbloquea un poder (toca una tarjeta o pulsa 1-4). '
                    'Cada uso tiene 20 s de recarga.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  for (final power in PowerType.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PowerCard(
                        power: power,
                        owned: engine.isUnlocked(power),
                        onTap: () => onChoose(power),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.power,
    required this.owned,
    required this.onTap,
  });

  final PowerType power;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: owned ? null : onTap,
      child: Opacity(
        opacity: owned ? 0.4 : 1,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(power.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    power.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    power.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (owned)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'YA DESBLOQUEADO',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${power.index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Botón táctil. Con [repeat] se repite mientras se mantiene presionado.
/// Usa eventos de puntero para no robarle el foco al teclado.
class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    this.repeat = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool repeat;
  final Color? color;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  Timer? _delayTimer;
  Timer? _repeatTimer;
  bool _pressed = false;

  void _onDown() {
    setState(() => _pressed = true);
    widget.onPressed();
    if (!widget.repeat) {
      return;
    }
    _delayTimer = Timer(const Duration(milliseconds: 220), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 70),
        (_) => widget.onPressed(),
      );
    });
  }

  void _onUp() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    _delayTimer = null;
    _repeatTimer = null;
    if (_pressed && mounted) {
      setState(() => _pressed = false);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? AppTheme.surfaceColor;
    return Listener(
      onPointerDown: (_) => _onDown(),
      onPointerUp: (_) => _onUp(),
      onPointerCancel: (_) => _onUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pressed ? base.withValues(alpha: 0.65) : base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(widget.icon, size: widget.size * 0.55, color: Colors.white),
      ),
    );
  }
}

/// Capa oscura sobre el tablero para la pausa y el game over.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.title,
    required this.lines,
    required this.actions,
  });

  final String title;
  final List<String> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: AppTheme.primaryColor, blurRadius: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: action,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return SizedBox(
      width: 210,
      height: 44,
      child: primary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: textStyle,
                shape: shape,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: textStyle,
                shape: shape,
              ),
              child: Text(label),
            ),
    );
  }
}