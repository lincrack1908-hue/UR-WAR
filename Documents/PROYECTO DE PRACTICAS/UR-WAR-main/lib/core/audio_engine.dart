import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Bounded voice pool playing original bundled PCM sound effects on every target.
/// Web playback starts from a user gesture; plugin failures never stop a match.
class AudioEngine {
  static bool _soundEnabled = true,
      _musicEnabled = true,
      _ready = false,
      _suspended = false;
  static double _soundVolume = .7, _musicVolume = .3;
  static String _track = 'menu';
  static AudioPlayer? _music;
  static final List<AudioPlayer> _voices = [];
  static final List<Future<void>> _voiceQueues = [];
  static Future<void> _musicQueue = Future.value();
  static int _voice = 0;
  static bool _reportedError = false;
  static final Map<String, DateTime> _lastPlayed = {};

  static bool get soundEnabled => _soundEnabled;
  static set soundEnabled(bool v) {
    _soundEnabled = v;
    if (!v) _stopEffects();
  }

  static bool get musicEnabled => _musicEnabled;
  static set musicEnabled(bool v) {
    _musicEnabled = v;
    if (_ready) {
      if (v) {
        startMusic(_track);
      } else {
        stopMusic();
      }
    }
  }

  static double get soundVolume => _soundVolume;
  static set soundVolume(double v) {
    _soundVolume = v.clamp(0, 1);
  }

  static double get musicVolume => _musicVolume;
  static set musicVolume(double v) {
    _musicVolume = v.clamp(0, 1);
    if (_music != null) _queueMusic(() => _music!.setVolume(_musicVolume));
  }

  /// Initialization is explicit so model and widget tests need no audio device.
  static void initialize() {
    _ready = true;
  }

  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!_reportedError) {
        debugPrint('[AudioEngine] Audio unavailable: $e');
        _reportedError = true;
      }
    }
  }

  static void _queueMusic(Future<void> Function() action) {
    _musicQueue = _musicQueue.then((_) => _safe(action));
  }

  static void startMusic([String track = 'menu']) {
    _track = track == 'battle' ? 'battle' : 'menu';
    if (!_ready || !_musicEnabled || _suspended) return;
    final asset = 'audio/music_$_track.wav';
    _queueMusic(() async {
      if (!_musicEnabled || _suspended) return;
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.play(AssetSource(asset), volume: _musicVolume);
    });
  }

  static void stopMusic() {
    if (_music != null) _queueMusic(() => _music!.stop());
  }

  static void suspend() {
    _suspended = true;
    stopMusic();
    _stopEffects();
  }

  static void resume() {
    _suspended = false;
    startMusic(_track);
  }

  static void _stopEffects() {
    for (int i = 0; i < _voices.length; i++) {
      final player = _voices[i];
      _voiceQueues[i] = _voiceQueues[i].then((_) => _safe(player.stop));
    }
  }

  static void _play(String effect) {
    if (!_ready || !_soundEnabled || _suspended || _soundVolume == 0) return;
    final now = DateTime.now();
    if (now.difference(_lastPlayed[effect] ?? DateTime(2000)).inMilliseconds <
        65) {
      return;
    }
    _lastPlayed[effect] = now;
    if (_voices.length < 6) {
      _voices.add(AudioPlayer());
      _voiceQueues.add(Future.value());
    }
    final index = _voice++ % _voices.length;
    final player = _voices[index];
    _voiceQueues[index] = _voiceQueues[index].then(
      (_) => _safe(() async {
        if (!_soundEnabled || _suspended) return;
        await player.stop();
        await player.play(
          AssetSource('audio/$effect.wav'),
          volume: _soundVolume,
        );
      }),
    );
  }

  static void playAttackSlash() => _play('slash');
  static void playShoot() => _play('shoot');
  static void playHit() => _play('hit');
  static void playCoin() => _play('coin');
  static void playLevelUp() => _play('levelup');
  static void playSpecialSkill() => _play('special');
  static void playBossAbility() => _play('special');
  static void playResurrection() => _play('levelup');
  static void playMagicImpact() => _play('hit');
  static void playRockLaunch() => _play('shoot');
  static void playRockImpact() => _play('hit');
  static void playVictory() => _play('victory');
  static void playDefeat() => _play('defeat');
  static Future<void> dispose() async {
    _ready = false;
    await _musicQueue;
    await Future.wait(_voiceQueues);
    await _safe(() async {
      await _music?.dispose();
      for (final player in _voices) {
        await player.dispose();
      }
    });
    _music = null;
    _voices.clear();
    _voiceQueues.clear();
    _lastPlayed.clear();
  }
}
