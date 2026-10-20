import 'package:flutter/material.dart';

/// Contextual guidance shown during the first campaign level.
class TutorialHint {
  final String id;
  final String title;
  final String message;
  final IconData icon;

  const TutorialHint({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
  });
}
