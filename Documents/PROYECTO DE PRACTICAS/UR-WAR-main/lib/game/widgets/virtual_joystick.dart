import 'package:flutter/material.dart';

/// One pointer owns each stick, so moving and aiming work simultaneously.
class VirtualJoystick extends StatefulWidget {
  final double radius;
  final ValueChanged<Offset> onDirectionChanged;
  final ValueChanged<Offset>? onTapField;
  final ValueChanged<bool>? onActiveChanged;
  final String label;
  final Color color;
  final int resetToken;

  const VirtualJoystick({
    super.key,
    this.radius = 48,
    required this.onDirectionChanged,
    this.onTapField,
    this.onActiveChanged,
    this.label = 'MOVER',
    this.color = const Color(0xFFC7AD79),
    this.resetToken = 0,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _pointer;
  Offset _delta = Offset.zero;

  @override
  void didUpdateWidget(covariant VirtualJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _pointer = null;
      _delta = Offset.zero;
    }
  }

  void _move(Offset position) {
    final raw = position - Offset(widget.radius, widget.radius);
    final maxTravel = widget.radius * .65;
    final distance = raw.distance;
    _delta = distance > maxTravel ? raw / distance * maxTravel : raw;
    widget.onDirectionChanged(distance < 6 ? Offset.zero : _delta / maxTravel);
    setState(() {});
  }

  void _release() {
    _pointer = null;
    _delta = Offset.zero;
    widget.onDirectionChanged(Offset.zero);
    widget.onActiveChanged?.call(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.radius * 2;
    return Semantics(
      label: widget.label == 'MOVER'
          ? 'Joystick de movimiento'
          : 'Apuntar y mantener para atacar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (_pointer != null) return;
              _pointer = event.pointer;
              widget.onActiveChanged?.call(true);
              _move(event.localPosition);
            },
            onPointerMove: (event) {
              if (event.pointer == _pointer) _move(event.localPosition);
            },
            onPointerUp: (event) {
              if (event.pointer == _pointer) _release();
            },
            onPointerCancel: (event) {
              if (event.pointer == _pointer) _release();
            },
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xE6191E1B),
                border: Border.all(
                  color: widget.color.withValues(alpha: .65),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.label == 'MOVER'
                        ? Icons.open_with
                        : Icons.my_location,
                    color: Colors.white24,
                    size: diameter * .65,
                  ),
                  Transform.translate(
                    offset: _delta,
                    child: Container(
                      width: diameter * .38,
                      height: diameter * .38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: _pointer == null ? .65 : 1,
                        ),
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}
