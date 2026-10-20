class Robot {
  final String id;
  final String name;
  int x;
  int y;
  int hp;
  int maxHp;
  int actionPoints;
  int attackRange;
  int attackDamage;

  Robot({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.hp = 100,
    this.maxHp = 100,
    this.actionPoints = 3,
    this.attackRange = 1,
    this.attackDamage = 30,
  });
}
