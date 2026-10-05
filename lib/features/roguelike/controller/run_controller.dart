import 'package:flutter/foundation.dart';
import '../model/relic.dart';
import '../model/sector_node.dart';

/// State of an active Roguelike Expedition run.
@immutable
class RunState {
  const RunState({
    required this.heroHp,
    required this.maxHeroHp,
    required this.aetherShards,
    required this.energyPerTurn,
    required this.currentDepth,
    required this.currentNodeIndex,
    required this.relics,
    required this.nodes,
    required this.isGameOver,
    required this.isVictory,
  });

  final int heroHp;
  final int maxHeroHp;
  final int aetherShards;
  final int energyPerTurn;
  final int currentDepth;
  final int currentNodeIndex;
  final List<Relic> relics;
  final List<List<SectorNode>> nodes;
  final bool isGameOver;
  final bool isVictory;

  /// Creates a fresh new expedition run with a 4-depth branching map.
  factory RunState.initial() {
    final List<List<SectorNode>> map = [
      // Depth 0: Starting Nodes
      [
        const SectorNode(id: '0_0', depth: 0, index: 0, type: NodeType.combat, title: 'Goblin Outpost', nextIndices: [0, 1]),
        const SectorNode(id: '0_1', depth: 0, index: 1, type: NodeType.combat, title: 'Frost Caves', nextIndices: [1, 2]),
      ],
      // Depth 1: Elite / Shrine
      [
        const SectorNode(id: '1_0', depth: 1, index: 0, type: NodeType.shrine, title: 'Aether Well', nextIndices: [0]),
        const SectorNode(id: '1_1', depth: 1, index: 1, type: NodeType.elite, title: 'Magma Wyrm', nextIndices: [0, 1]),
        const SectorNode(id: '1_2', depth: 1, index: 2, type: NodeType.merchant, title: 'Wandering Djinn', nextIndices: [1]),
      ],
      // Depth 2: Pre-boss Challenge
      [
        const SectorNode(id: '2_0', depth: 2, index: 0, type: NodeType.elite, title: 'Cryo Sentinel', nextIndices: [0]),
        const SectorNode(id: '2_1', depth: 2, index: 1, type: NodeType.mystery, title: 'Wormhole Rift', nextIndices: [0]),
      ],
      // Depth 3: Sector Boss
      [
        const SectorNode(id: '3_0', depth: 3, index: 0, type: NodeType.boss, title: 'Archmage Hexor', nextIndices: []),
      ],
    ];

    return RunState(
      heroHp: 100,
      maxHeroHp: 100,
      aetherShards: 50,
      energyPerTurn: 3,
      currentDepth: 0,
      currentNodeIndex: 0,
      relics: [],
      nodes: map,
      isGameOver: false,
      isVictory: false,
    );
  }

  RunState copyWith({
    int? heroHp,
    int? maxHeroHp,
    int? aetherShards,
    int? energyPerTurn,
    int? currentDepth,
    int? currentNodeIndex,
    List<Relic>? relics,
    List<List<SectorNode>>? nodes,
    bool? isGameOver,
    bool? isVictory,
  }) {
    return RunState(
      heroHp: heroHp ?? this.heroHp,
      maxHeroHp: maxHeroHp ?? this.maxHeroHp,
      aetherShards: aetherShards ?? this.aetherShards,
      energyPerTurn: energyPerTurn ?? this.energyPerTurn,
      currentDepth: currentDepth ?? this.currentDepth,
      currentNodeIndex: currentNodeIndex ?? this.currentNodeIndex,
      relics: relics ?? this.relics,
      nodes: nodes ?? this.nodes,
      isGameOver: isGameOver ?? this.isGameOver,
      isVictory: isVictory ?? this.isVictory,
    );
  }
}

/// Controller managing run persistence, sector traversal, and loot drafting.
class RunController extends ChangeNotifier {
  RunController({RunState? initial}) : _state = initial ?? RunState.initial();

  RunState _state;
  RunState get state => _state;

  void takeDamage(int amount) {
    final nextHp = (_state.heroHp - amount).clamp(0, _state.maxHeroHp);
    _state = _state.copyWith(
      heroHp: nextHp,
      isGameOver: nextHp == 0,
    );
    notifyListeners();
  }

  void heal(int amount) {
    final nextHp = (_state.heroHp + amount).clamp(0, _state.maxHeroHp);
    _state = _state.copyWith(heroHp: nextHp);
    notifyListeners();
  }

  void addShards(int amount) {
    _state = _state.copyWith(aetherShards: _state.aetherShards + amount);
    notifyListeners();
  }

  void addRelic(Relic relic) {
    final updated = List<Relic>.from(_state.relics)..add(relic);
    int extraEnergy = relic.bonusEnergy;
    _state = _state.copyWith(
      relics: updated,
      energyPerTurn: _state.energyPerTurn + extraEnergy,
    );
    notifyListeners();
  }

  void completeCurrentNodeAndAdvance(int nextNodeIndex) {
    final nextDepth = _state.currentDepth + 1;
    if (nextDepth >= _state.nodes.length) {
      _state = _state.copyWith(isVictory: true);
    } else {
      _state = _state.copyWith(
        currentDepth: nextDepth,
        currentNodeIndex: nextNodeIndex,
      );
    }
    notifyListeners();
  }

  void resetRun() {
    _state = RunState.initial();
    notifyListeners();
  }
}
