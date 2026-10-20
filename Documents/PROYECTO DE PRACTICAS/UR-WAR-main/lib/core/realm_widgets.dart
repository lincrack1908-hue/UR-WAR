import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Clips one original illustration from an atlas without creating extra files.
class AtlasArt extends StatelessWidget {
  final String asset;
  final int index, count;
  final double panelAspect;
  final double verticalAlignment;
  const AtlasArt({
    super.key,
    required this.asset,
    required this.index,
    required this.count,
    required this.panelAspect,
    this.verticalAlignment = 0,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      final height = box.maxHeight;
      final panelWidth = width > height * panelAspect
          ? width
          : height * panelAspect;
      final artHeight = panelWidth / panelAspect;
      return ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: (width - panelWidth) / 2 - index * panelWidth,
              top: (height - artHeight) * (verticalAlignment + 1) / 2,
              width: panelWidth * count,
              height: artHeight,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class RealmBackground extends StatelessWidget {
  final Widget child;
  const RealmBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF24251F), AppTheme.darkBackground, Color(0xFF151918)],
      ),
    ),
    child: child,
  );
}

class RealmHeading extends StatelessWidget {
  final String title, subtitle;
  const RealmHeading({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
