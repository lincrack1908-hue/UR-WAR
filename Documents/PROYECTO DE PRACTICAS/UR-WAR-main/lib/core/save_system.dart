import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_engine.dart';

/// Versioned, local profile. A match is recorded once by the game engine.
class SaveData {
  int highScore, totalKills, totalGoldGathered, unlockedCampaignLevel;
  bool soundEnabled,
      musicEnabled,
      autoAttack,
      aimAssist,
      leftHanded,
      tutorialSeen,
      tutorialHintsEnabled;
  double soundVolume, musicVolume, controlScale;
  final Map<String, int> levelStars, levelScores, keyBindings;
  final Set<String> tutorialHintsSeen;

  SaveData({
    this.highScore = 0,
    this.totalKills = 0,
    this.totalGoldGathered = 0,
    this.unlockedCampaignLevel = 1,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = .7,
    this.musicVolume = .3,
    this.autoAttack = false,
    this.aimAssist = true,
    this.controlScale = 1,
    this.leftHanded = false,
    this.tutorialSeen = false,
    this.tutorialHintsEnabled = true,
    Map<String, int>? levelStars,
    Map<String, int>? levelScores,
    Map<String, int>? keyBindings,
    Set<String>? tutorialHintsSeen,
  }) : levelStars = levelStars ?? {},
       levelScores = levelScores ?? {},
       keyBindings = {...defaultKeyBindings, ...?keyBindings},
       tutorialHintsSeen = tutorialHintsSeen ?? {};

  static Map<String, int> get defaultKeyBindings => {
    'moveUp': LogicalKeyboardKey.keyW.keyId,
    'moveDown': LogicalKeyboardKey.keyS.keyId,
    'moveLeft': LogicalKeyboardKey.keyA.keyId,
    'moveRight': LogicalKeyboardKey.keyD.keyId,
    'attack': LogicalKeyboardKey.space.keyId,
    'special': LogicalKeyboardKey.keyE.keyId,
    'dash': LogicalKeyboardKey.shiftLeft.keyId,
    'interact': LogicalKeyboardKey.keyF.keyId,
    'shop': LogicalKeyboardKey.keyB.keyId,
    'pause': LogicalKeyboardKey.escape.keyId,
  };

  Map<String, dynamic> toJson() => {
    'version': 1,
    'highScore': highScore,
    'totalKills': totalKills,
    'totalGoldGathered': totalGoldGathered,
    'unlockedCampaignLevel': unlockedCampaignLevel,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'soundVolume': soundVolume,
    'musicVolume': musicVolume,
    'autoAttack': autoAttack,
    'aimAssist': aimAssist,
    'controlScale': controlScale,
    'leftHanded': leftHanded,
    'tutorialSeen': tutorialSeen,
    'tutorialHintsEnabled': tutorialHintsEnabled,
    'tutorialHintsSeen': tutorialHintsSeen.toList(),
    'levelStars': levelStars,
    'levelScores': levelScores,
    'keyBindings': keyBindings,
  };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    int integer(String k, [int fallback = 0]) =>
        json[k] is num ? math.max(0, (json[k] as num).toInt()) : fallback;
    bool boolean(String k, bool fallback) =>
        json[k] is bool ? json[k] as bool : fallback;
    double decimal(String k, double fallback, double min, double max) {
      final n = json[k];
      return n is num && n.isFinite ? n.toDouble().clamp(min, max) : fallback;
    }

    Map<String, int> intMap(String k, int max) {
      final v = json[k];
      if (v is! Map) return {};
      return {
        for (final e in v.entries)
          if (e.key is String && e.value is num)
            e.key as String: (e.value as num).toInt().clamp(0, max),
      };
    }

    Set<String> stringSet(String k) {
      final value = json[k];
      if (value is! List) return {};
      return value.whereType<String>().toSet();
    }

    return SaveData(
      highScore: integer('highScore'),
      totalKills: integer('totalKills'),
      totalGoldGathered: integer('totalGoldGathered'),
      unlockedCampaignLevel: integer('unlockedCampaignLevel', 1).clamp(1, 5),
      soundEnabled: boolean('soundEnabled', true),
      musicEnabled: boolean('musicEnabled', true),
      soundVolume: decimal('soundVolume', .7, 0, 1),
      musicVolume: decimal('musicVolume', .3, 0, 1),
      autoAttack: boolean('autoAttack', false),
      aimAssist: boolean('aimAssist', true),
      controlScale: decimal('controlScale', 1, .8, 1.3),
      leftHanded: boolean('leftHanded', false),
      tutorialSeen: boolean('tutorialSeen', false),
      tutorialHintsEnabled: boolean('tutorialHintsEnabled', true),
      tutorialHintsSeen: stringSet('tutorialHintsSeen'),
      levelStars: intMap('levelStars', 3),
      levelScores: intMap('levelScores', 2147483647),
      keyBindings: intMap('keyBindings', 0x1fffffffffffff),
    );
  }
}

class SaveSystem {
  static const storageKey = 'ur_war.profile.v1';
  static SaveData _data = SaveData();
  static SharedPreferences? _preferences;
  static Future<void> _pendingWrite = Future.value();
  static String? lastError;
  static SaveData get data => _data;

  static Future<void> initialize({SharedPreferences? preferences}) async {
    await _pendingWrite;
    lastError = null;
    try {
      _preferences = preferences ?? await SharedPreferences.getInstance();
      final raw = _preferences!.getString(storageKey);
      _data = raw == null
          ? SaveData()
          : SaveData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      _data = SaveData();
      lastError =
          'No se pudo cargar el perfil local. Revisa el almacenamiento disponible.';
      debugPrint('[SaveSystem] $error');
    }
    _syncAudio();
  }

  static void _syncAudio() {
    AudioEngine.soundEnabled = _data.soundEnabled;
    AudioEngine.musicEnabled = _data.musicEnabled;
    AudioEngine.soundVolume = _data.soundVolume;
    AudioEngine.musicVolume = _data.musicVolume;
  }

  static void updateHighScore(int score) {
    if (score > _data.highScore) {
      _data.highScore = score;
      save();
    }
  }

  static void addMatchStats({
    required int kills,
    required int gold,
    required int score,
  }) {
    _data.totalKills += math.max(0, kills);
    _data.totalGoldGathered += math.max(0, gold);
    _data.highScore = math.max(score, _data.highScore);
    save();
  }

  static void unlockLevel(int levelIndex) {
    _data.unlockedCampaignLevel = math.max(
      _data.unlockedCampaignLevel,
      levelIndex.clamp(1, 5),
    );
    save();
  }

  static void completeLevel(
    String mapId, {
    required int levelNumber,
    required int stars,
    required int score,
  }) {
    _data.levelStars[mapId] = math.max(starsFor(mapId), stars.clamp(1, 3));
    _data.levelScores[mapId] = math.max(_data.levelScores[mapId] ?? 0, score);
    _data.unlockedCampaignLevel = math.max(
      _data.unlockedCampaignLevel,
      (levelNumber + 1).clamp(1, 5),
    );
    save();
  }

  static int starsFor(String mapId) => _data.levelStars[mapId] ?? 0;
  static bool isLevelUnlocked(int levelNumber) =>
      levelNumber >= 1 && levelNumber <= _data.unlockedCampaignLevel;
  static void setSoundEnabled(bool value) {
    _data.soundEnabled = value;
    _syncAudio();
    save();
  }

  static void setMusicEnabled(bool value) {
    _data.musicEnabled = value;
    _syncAudio();
    save();
  }

  static void setSoundVolume(double value) {
    _data.soundVolume = value.clamp(0, 1);
    _syncAudio();
    save();
  }

  static void setMusicVolume(double value) {
    _data.musicVolume = value.clamp(0, 1);
    _syncAudio();
    save();
  }

  static void setAutoAttack(bool value) {
    _data.autoAttack = value;
    save();
  }

  static void setAimAssist(bool value) {
    _data.aimAssist = value;
    save();
  }

  static void setControlScale(double value) {
    _data.controlScale = value.clamp(.8, 1.3);
    save();
  }

  static void setLeftHanded(bool value) {
    _data.leftHanded = value;
    save();
  }

  static void setTutorialSeen(bool value) {
    _data.tutorialSeen = value;
    save();
  }

  static bool hasSeenTutorialHint(String id) =>
      _data.tutorialHintsSeen.contains(id);

  static void markTutorialHintSeen(String id) {
    if (_data.tutorialHintsSeen.add(id)) save();
  }

  static bool get tutorialHintsEnabled => _data.tutorialHintsEnabled;

  static void setTutorialHintsEnabled(bool value) {
    _data.tutorialHintsEnabled = value;
    save();
  }

  static void resetTutorialHints() {
    _data.tutorialHintsEnabled = true;
    _data.tutorialHintsSeen.clear();
    save();
  }

  /// Swapping a used key avoids unreachable actions after remapping.
  static void setKeyBinding(String action, int keyId) {
    if (!_data.keyBindings.containsKey(action)) return;
    final old = _data.keyBindings[action]!;
    for (final key in _data.keyBindings.keys.toList()) {
      if (key != action && _data.keyBindings[key] == keyId) {
        _data.keyBindings[key] = old;
      }
    }
    _data.keyBindings[action] = keyId;
    save();
  }

  static void resetKeyBindings() {
    _data.keyBindings
      ..clear()
      ..addAll(SaveData.defaultKeyBindings);
    save();
  }

  /// Serializes writes so rapidly moving a slider cannot restore an older value.
  static void save() {
    final preferences = _preferences;
    if (preferences == null) return;
    final encoded = jsonEncode(_data.toJson());
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        if (!await preferences.setString(storageKey, encoded)) {
          throw StateError('Write rejected');
        }
        lastError = null;
      } catch (error) {
        lastError =
            'No se pudo guardar el perfil. Revisa el almacenamiento disponible.';
        debugPrint('[SaveSystem] $error');
      }
    });
  }

  static Future<void> flush() => _pendingWrite;
}
