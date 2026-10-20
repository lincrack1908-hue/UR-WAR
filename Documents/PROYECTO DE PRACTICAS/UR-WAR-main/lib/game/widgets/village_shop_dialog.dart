import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/entity.dart';

class VillageShopDialog extends StatefulWidget {
  final GameEngine engine;
  const VillageShopDialog({super.key, required this.engine});
  @override
  State<VillageShopDialog> createState() => _VillageShopDialogState();
}

class _VillageShopDialogState extends State<VillageShopDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.engine,
    builder: (context, _) {
      final player = widget.engine.player;
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFF1C201F),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 650),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, color: Color(0xFFC7AD79)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARMERÍA DE LA ALDEA',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cinzel',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Nivel ${player.level} · ${player.skillPoints} puntos · ${player.gold} oro',
                            style: const TextStyle(
                              color: Color(0xFFC7AD79),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar tienda',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFFC7AD79),
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(text: 'MEJORAS'),
                    Tab(text: 'CONSTRUIR'),
                    Tab(text: 'HABILIDADES'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_upgrades(), _buildings(), _skills()],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('VOLVER A LA BATALLA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _upgrades() {
    final e = widget.engine;
    return ListView(
      children: [
        _item(
          'Reparar la aldea',
          'Recupera 300 de salud del salón y 150 de las demás defensas.',
          Icons.fort,
          75,
          () => e.repairVillage(75, 300),
          enabled: e.villageBuildings.any(
            (b) => !b.isDead && b.health < b.maxHealth,
          ),
        ),
        _item(
          'Poción de vitalidad',
          'Restaura el 60% de la salud de tu héroe.',
          Icons.favorite,
          60,
          () => e.healHero(60),
          enabled: e.player.health < e.player.maxHealth,
        ),
        _item(
          'Forjar acero',
          '+25% de daño durante esta partida.',
          Icons.colorize,
          120,
          () => e.upgradeHeroDamage(120),
        ),
        _item(
          'Botas de la tempestad',
          '+15% de velocidad durante esta partida.',
          Icons.directions_run,
          90,
          () => e.upgradeHeroSpeed(90),
        ),
      ],
    );
  }

  Widget _buildings() => ListView(
    children: [
      const Padding(
        padding: EdgeInsets.all(4),
        child: Text(
          'Elige una defensa y después toca su posición en el campo. Solo se cobra al confirmar.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
      for (final type in [
        BuildingType.watchtower,
        BuildingType.frostTower,
        BuildingType.cannonTower,
        BuildingType.barricade,
        BuildingType.goldMine,
      ])
        _item(
          BuildingSpec.forType(type).name,
          _description(type),
          _icon(type),
          BuildingSpec.forType(type).cost,
          () {
            widget.engine.showTutorialForBuildingType(type);
            if (widget.engine.beginConstruction(
              type,
              BuildingSpec.forType(type).cost,
            )) {
              Navigator.pop(context);
            }
          },
        ),
    ],
  );

  Widget _skills() {
    final e = widget.engine;
    return ListView(
      children: [
        for (final skill in e.player.playerClass.skillTree)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: _tile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(skill.icon, color: const Color(0xFFC7AD79), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        skill.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cinzel',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  skill.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'Requiere nivel ${skill.requiredLevel}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    FilledButton(
                      onPressed:
                          e.player.skillPoints > 0 &&
                              e.player.level >= skill.requiredLevel &&
                              !e.player.unlockedSkillIds.contains(skill.id)
                          ? () => e.unlockSkill(skill.id)
                          : null,
                      child: Text(
                        e.player.unlockedSkillIds.contains(skill.id)
                            ? 'Aprendida'
                            : 'Aprender · 1 punto',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _item(
    String title,
    String description,
    IconData icon,
    int cost,
    VoidCallback action, {
    bool enabled = true,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: _tile,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFC7AD79), size: 23),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cinzel',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: !enabled
                ? null
                : () {
                    if (widget.engine.player.gold < cost) {
                      widget.engine.showTutorialForInsufficientGold();
                      return;
                    }
                    action();
                  },
            child: Text('$cost oro'),
          ),
        ),
      ],
    ),
  );

  static final _tile = BoxDecoration(
    color: const Color(0xFF2B2D26),
    border: Border.all(color: Colors.white12),
    borderRadius: BorderRadius.circular(4),
  );
  static IconData _icon(BuildingType type) => switch (type) {
    BuildingType.watchtower => Icons.fort,
    BuildingType.frostTower => Icons.ac_unit,
    BuildingType.cannonTower => Icons.flare,
    BuildingType.barricade => Icons.fence,
    _ => Icons.monetization_on,
  };
  static String _description(BuildingType type) => switch (type) {
    BuildingType.watchtower =>
      'Ataques rápidos contra un objetivo. Ideal para cubrir caminos y accesos estrechos.',
    BuildingType.frostTower =>
      'Ralentiza a los enemigos para que las demás defensas puedan atacarlos durante más tiempo.',
    BuildingType.cannonTower =>
      'Disparos explosivos de área. Eficaz contra grupos, pero dispara lentamente.',
    BuildingType.barricade =>
      'Bloquea el paso y desvía enemigos. Colócala delante de tus torres, sin cerrar todos los caminos.',
    _ =>
      'Produce oro periódicamente. Constrúyela lejos de los accesos y protégela de los saqueadores.',
  };
}
