import 'package:flutter/material.dart';
import '../../../core/theme/tactical_theme.dart';
import '../../combat/view/combat_screen.dart';
import '../controller/run_controller.dart';
import '../model/relic.dart';
import '../model/sector_node.dart';

/// Interactive branching campaign map screen for the roguelike expedition.
class SectorMapScreen extends StatelessWidget {
  const SectorMapScreen({
    super.key,
    required this.runController,
  });

  final RunController runController;

  void _onNodeSelected(BuildContext context, SectorNode node) async {
    if (node.type == NodeType.shrine) {
      runController.heal(30);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Restored +30 HP at the Aether Shrine!')),
      );
      _showRelicRewardDialog(context);
      return;
    }

    if (node.type == NodeType.merchant) {
      _showRelicRewardDialog(context);
      return;
    }

    // Launch tactical combat
    final victory = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(runController: runController, node: node),
      ),
    );

    if (victory == true && context.mounted) {
      _showRelicRewardDialog(context);
    }
  }

  void _showRelicRewardDialog(BuildContext context) {
    final available = Relic.catalog.where((r) => !runController.state.relics.contains(r)).toList();
    if (available.isEmpty) {
      runController.completeCurrentNodeAndAdvance(0);
      return;
    }

    available.shuffle();
    final choices = available.take(2).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.surface,
        title: const Text('🎁 Draft a Passive Relic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: choices.map((relic) {
            return Card(
              color: TacticalTheme.background,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Text(relic.icon, style: const TextStyle(fontSize: 26)),
                title: Text(relic.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(relic.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                onTap: () {
                  runController.addRelic(relic);
                  Navigator.pop(ctx);
                  runController.completeCurrentNodeAndAdvance(0);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: runController,
      builder: (context, _) {
        final state = runController.state;

        if (state.isVictory) {
          return Scaffold(
            backgroundColor: TacticalTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    const Text('EXPEDITION CONQUERED!',
                        style: TextStyle(color: TacticalTheme.teslaGold, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Total Shards: ${state.aetherShards} 🪙', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: TacticalTheme.playerHero),
                      onPressed: () => runController.resetRun(),
                      child: const Text('Start New Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.isGameOver) {
          return Scaffold(
            backgroundColor: TacticalTheme.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💀', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  const Text('EXPEDITION FAILED',
                      style: TextStyle(color: TacticalTheme.playerEnemy, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: TacticalTheme.playerHero),
                    onPressed: () => runController.resetRun(),
                    child: const Text('Try Again', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: TacticalTheme.background,
          appBar: AppBar(
            backgroundColor: TacticalTheme.surface,
            title: const Text('🗺️ Sector Expedition Map'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Text('❤️ ${state.heroHp}/${state.maxHeroHp}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      const SizedBox(width: 12),
                      Text('🪙 ${state.aetherShards}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.teslaGold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Relics Bar
              if (state.relics.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: TacticalTheme.surface.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      const Text('Relics: ', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: state.relics.map<Widget>((Relic r) => Tooltip(message: '${r.name}: ${r.description}', child: Text(r.icon, style: const TextStyle(fontSize: 18)))).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tree View of Nodes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  itemCount: state.nodes.length,
                  itemBuilder: (context, depthIndex) {
                    final List<SectorNode> row = state.nodes[depthIndex];
                    final isCurrentDepth = depthIndex == state.currentDepth;
                    final isPassedDepth = depthIndex < state.currentDepth;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Text('DEPTH ${depthIndex + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrentDepth ? TacticalTheme.playerHero : Colors.white30,
                              )),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.map<Widget>((SectorNode node) {
                              final isSelectable = isCurrentDepth;
                              return GestureDetector(
                                onTap: isSelectable ? () => _onNodeSelected(context, node) : null,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isPassedDepth
                                        ? Colors.white12
                                        : isSelectable
                                            ? TacticalTheme.surface
                                            : Colors.black26,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelectable ? TacticalTheme.playerHero : Colors.white12,
                                      width: isSelectable ? 2.5 : 1.0,
                                    ),
                                    boxShadow: isSelectable
                                        ? [
                                            BoxShadow(color: TacticalTheme.playerHero.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(node.icon, style: const TextStyle(fontSize: 28)),
                                      const SizedBox(height: 4),
                                      Text(
                                        node.title,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelectable ? Colors.white : Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
