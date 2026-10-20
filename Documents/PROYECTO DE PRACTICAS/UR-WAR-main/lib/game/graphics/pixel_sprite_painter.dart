import 'package:flutter/material.dart';
import 'realm_illustration.dart';
import 'pixel_art_data.dart';

/// Compatibility adapter: existing entity assets now use smooth vector art.
/// Scaling, facing, hit flashes and shadows preserve the original game API.
class PixelSpritePainter extends CustomPainter {
  final PixelSpriteData sprite;
  final double pixelSize;
  final bool flipX;
  final Color? tintColor;
  final double tintIntensity;
  final bool drawShadow;

  PixelSpritePainter({
    required this.sprite,
    this.pixelSize = 3.0,
    this.flipX = false,
    this.tintColor,
    this.tintIntensity = 0.0,
    this.drawShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final totalWidth = sprite.width * pixelSize;
    final totalHeight = sprite.height * pixelSize;

    // Sombra proyectada en el suelo
    if (drawShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(totalWidth / 2, totalHeight - pixelSize * 0.5),
          width: totalWidth * 0.8,
          height: pixelSize * 3.5,
        ),
        shadowPaint,
      );
    }

    if (flipX) {
      canvas.translate(totalWidth, 0);
      canvas.scale(-1, 1);
    }

    final tinted = tintColor != null && tintIntensity > 0;
    if (tinted) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, totalWidth, totalHeight),
        Paint()
          ..colorFilter = ColorFilter.mode(
            tintColor!.withValues(alpha: tintIntensity.clamp(0, 1)),
            BlendMode.srcATop,
          ),
      );
    }
    RealmIllustration.draw(canvas, Size(totalWidth, totalHeight), sprite);
    if (tinted) canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PixelSpritePainter oldDelegate) {
    return oldDelegate.sprite != sprite ||
        oldDelegate.pixelSize != pixelSize ||
        oldDelegate.flipX != flipX ||
        oldDelegate.tintColor != tintColor ||
        oldDelegate.tintIntensity != tintIntensity ||
        oldDelegate.drawShadow != drawShadow;
  }
}

/// Widget reutilizable para mostrar un sprite de Pixel Art con animación sutil
class PixelSpriteWidget extends StatelessWidget {
  final PixelSpriteData sprite;
  final double pixelSize;
  final bool flipX;
  final Color? tintColor;
  final double tintIntensity;
  final bool animateBobbing;
  final double bobbingOffset;

  const PixelSpriteWidget({
    super.key,
    required this.sprite,
    this.pixelSize = 3.5,
    this.flipX = false,
    this.tintColor,
    this.tintIntensity = 0.0,
    this.animateBobbing = false,
    this.bobbingOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final width = sprite.width * pixelSize;
    final height = sprite.height * pixelSize;

    Widget child = CustomPaint(
      size: Size(width, height),
      painter: PixelSpritePainter(
        sprite: sprite,
        pixelSize: pixelSize,
        flipX: flipX,
        tintColor: tintColor,
        tintIntensity: tintIntensity,
      ),
    );

    if (animateBobbing && bobbingOffset != 0) {
      child = Transform.translate(
        offset: Offset(0, bobbingOffset),
        child: child,
      );
    }

    return SizedBox(width: width, height: height, child: child);
  }
}
