import 'package:flutter/material.dart';
import 'pixel_art_data.dart';

/// Pose data consumed by the continuous vector renderer; no frame allocations of pixels.
class SpriteAnimation {
  static PixelSpriteData frame(
    PixelSpriteData sprite, {
    double phase = 0,
    bool moving = false,
    bool facingAway = false,
    bool attacking = false,
  }) => PixelSpriteData(
    visualId: sprite.visualId,
    phase: phase,
    moving: moving,
    facingAway: facingAway,
    attacking: attacking,
    width: sprite.width,
    height: sprite.height,
    matrix: sprite.matrix,
    palette: sprite.palette,
  );

  static PixelSpriteData recolor(
    PixelSpriteData sprite,
    Map<String, Color> colors,
  ) => PixelSpriteData(
    visualId: sprite.visualId == 'forestTree' ? 'snowTree' : sprite.visualId,
    width: sprite.width,
    height: sprite.height,
    matrix: sprite.matrix,
    palette: {...sprite.palette, ...colors},
  );
}
