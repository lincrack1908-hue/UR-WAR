import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/robot.dart';

class GameState extends ChangeNotifier {
  final int boardSize = 8;
  List<Robot> robots = [];
  int currentTurn = 1;
  String? selectedRobotId;
  String? logs;
  bool isGameOver = false;
  String winnerMessage = '';

  GameState() {
    _initializeGame();
  }

  Robot? get selectedRobot => robots
      .where((robot) => robot.id == selectedRobotId && robot.hp > 0)
      .firstOrNull;

  Robot? get activePlayerRobot =>
      selectedRobot ??
      robots
          .where((robot) => robot.id.startsWith('p') && robot.hp > 0)
          .firstOrNull;

  bool canMoveTo(int x, int y) {
    final robot = selectedRobot;
    if (isGameOver || robot == null || robot.actionPoints <= 0) return false;

    final isOccupied = robots.any(
      (other) => other.hp > 0 && other.x == x && other.y == y,
    );
    final distance = (robot.x - x).abs() + (robot.y - y).abs();
    return !isOccupied && distance == 1;
  }

  bool canAttackAt(int x, int y) {
    final robot = selectedRobot;
    if (isGameOver || robot == null || robot.actionPoints <= 0) return false;

    final enemy = robots
        .where(
          (other) =>
              other.id.startsWith('e') &&
              other.hp > 0 &&
              other.x == x &&
              other.y == y,
        )
        .firstOrNull;
    if (enemy == null) return false;

    final distance = (robot.x - x).abs() + (robot.y - y).abs();
    return distance <= robot.attackRange;
  }

  void _initializeGame() {
    robots = [
      Robot(
        id: 'player_1',
        name: 'Guardián de acero',
        x: 1,
        y: 1,
        hp: 100,
        maxHp: 100,
        attackRange: 1,
        attackDamage: 35,
      ),
      Robot(
        id: 'enemy_1',
        name: 'Titán de asedio',
        x: 6,
        y: 6,
        hp: 100,
        maxHp: 100,
        attackRange: 1,
        attackDamage: 25,
      ),
    ];
    currentTurn = 1;
    selectedRobotId = null;
    isGameOver = false;
    winnerMessage = '';
    logs =
        '¡Bienvenido a la Arena Táctica por Turnos! Selecciona a tu guardián de acero para moverte o atacar.';
    notifyListeners();
  }

  void resetGame() {
    _initializeGame();
  }

  void onCellTapped(int x, int y) {
    if (isGameOver) return;

    var robotAtCell = robots
        .where((r) => r.x == x && r.y == y && r.hp > 0)
        .firstOrNull;

    if (selectedRobotId == null) {
      // Selección de robot del jugador
      if (robotAtCell != null && robotAtCell.id.startsWith('p')) {
        selectedRobotId = robotAtCell.id;
        logs =
            'Robot ${robotAtCell.name} seleccionado. Toca una casilla adyacente para moverte o a un enemigo para atacar.';
        notifyListeners();
      }
    } else {
      var selectedRobot = robots.firstWhere((r) => r.id == selectedRobotId);

      if (robotAtCell == null) {
        // Movimiento a casilla vacía
        int distanceX = (selectedRobot.x - x).abs();
        int distanceY = (selectedRobot.y - y).abs();
        bool isOneStep = (distanceX + distanceY) == 1;

        if (isOneStep && selectedRobot.actionPoints > 0) {
          selectedRobot.x = x;
          selectedRobot.y = y;
          selectedRobot.actionPoints -= 1;
          logs =
              '${selectedRobot.name} se movió a ($x, $y). Puntos de acción restantes: ${selectedRobot.actionPoints}.';

          if (selectedRobot.actionPoints <= 0) {
            selectedRobotId = null;
          }
        } else {
          selectedRobotId = null;
          logs = 'Movimiento cancelado. Selecciona una casilla contigua vacía.';
        }
        notifyListeners();
      } else if (robotAtCell.id.startsWith('e')) {
        // Ataque a robot enemigo
        int distanceX = (selectedRobot.x - x).abs();
        int distanceY = (selectedRobot.y - y).abs();
        bool inRange = (distanceX + distanceY) <= selectedRobot.attackRange;

        if (inRange && selectedRobot.actionPoints > 0) {
          robotAtCell.hp = max(0, robotAtCell.hp - selectedRobot.attackDamage);
          selectedRobot.actionPoints -= 1;
          logs =
              '¡${selectedRobot.name} atacó a ${robotAtCell.name} infligiendo ${selectedRobot.attackDamage} de daño! HP enemigo: ${robotAtCell.hp}.';

          if (robotAtCell.hp <= 0) {
            logs = '¡${robotAtCell.name} ha sido destruido! ¡VICTORIA!';
            isGameOver = true;
            winnerMessage = '¡VICTORIA DEL JUGADOR!';
          }

          if (selectedRobot.actionPoints <= 0) {
            selectedRobotId = null;
          }
        } else {
          selectedRobotId = null;
          logs = 'Enemigo fuera de alcance o sin puntos de acción suficientes.';
        }
        notifyListeners();
      } else if (robotAtCell.id == selectedRobotId) {
        selectedRobotId = null;
        logs = 'Robot deseleccionado.';
        notifyListeners();
      }
    }
  }

  void endTurn() {
    if (isGameOver) return;

    // 1. Turno de la IA Enemiga
    _playEnemyTurn();

    if (isGameOver) {
      notifyListeners();
      return;
    }

    // 2. Reiniciar turno para el jugador
    currentTurn++;
    for (var robot in robots) {
      robot.actionPoints = 3;
    }

    selectedRobotId = null;
    notifyListeners();
  }

  void _playEnemyTurn() {
    var player = robots
        .where((r) => r.id.startsWith('p') && r.hp > 0)
        .firstOrNull;
    var enemy = robots
        .where((r) => r.id.startsWith('e') && r.hp > 0)
        .firstOrNull;

    if (player == null || enemy == null) return;

    enemy.actionPoints = 3;

    while (enemy.actionPoints > 0 && player.hp > 0) {
      int distanceX = (player.x - enemy.x).abs();
      int distanceY = (player.y - enemy.y).abs();
      int totalDist = distanceX + distanceY;

      if (totalDist <= enemy.attackRange) {
        // Atacar al jugador
        player.hp = max(0, player.hp - enemy.attackDamage);
        enemy.actionPoints--;
        logs =
            '¡El enemigo ${enemy.name} te ha atacado causando ${enemy.attackDamage} de daño! Tu HP: ${player.hp}.';

        if (player.hp <= 0) {
          isGameOver = true;
          winnerMessage = '¡DERROTA! Tu guardián de acero ha sido destruido.';
          break;
        }
      } else {
        // Avanzar hacia el jugador
        int diffX = player.x - enemy.x;
        int diffY = player.y - enemy.y;

        if (diffX.abs() > diffY.abs()) {
          enemy.x += diffX.sign;
        } else {
          enemy.y += diffY.sign;
        }

        enemy.actionPoints--;
        logs = 'El enemigo ${enemy.name} avanza hacia tu posición.';
      }
    }
  }

  void moveInDirection(int dx, int dy) {
    if (isGameOver) return;
    if (selectedRobotId == null) {
      final playerRobot = robots
          .where((r) => r.id.startsWith('p') && r.hp > 0)
          .firstOrNull;
      if (playerRobot != null) {
        selectedRobotId = playerRobot.id;
      }
    }
    if (selectedRobotId != null) {
      final selectedRobot = robots.firstWhere((r) => r.id == selectedRobotId);
      final targetX = (selectedRobot.x + dx).clamp(0, boardSize - 1);
      final targetY = (selectedRobot.y + dy).clamp(0, boardSize - 1);
      onCellTapped(targetX, targetY);
    }
  }
}
