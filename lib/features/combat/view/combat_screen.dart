import 'package:flutter/material.dart';
import '../../../core/audio/tactical_audio.dart';
import '../../../core/geometry/hex_coord.dart';
import '../../../core/geometry/hex_layout.dart';
import '../../../core/theme/tactical_theme.dart';
import '../../ai/hex_tactical_ai.dart';
import '../../engine/controller/hex_game_engine.dart';
import '../../engine/model/hex_board.dart';
import '../../engine/model/hex_cell.dart';
import '../../engine/model/hex_wave_event.dart';
import '../../roguelike/controller/run_controller.dart';
import '../../roguelike/model/sector_node.dart';
import 'hex_board_painter.dart';

/// Screen managing active tactical combat against AI sector bosses.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.runController,
    required this.node,
  });

  final RunController runController;
  final SectorNode node;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final HexGameEngine _engine = const HexGameEngine();
  final HexTacticalAi _ai = const HexTacticalAi();

  late HexBoard _board;
  int _currentEnergy = 3;
  int _maxEnergy = 3;
  bool _isPlayerTurn = true;
  bool _isResolvingCascade = false;
  HexCoord? _hoveredCoord;

  final int _humanId = 1;
  final int _aiId = 2;

  int _enemyHp = 60;
  int _maxEnemyHp = 60;

  @override
  void initState() {
    super.initState();
    _initEncounter();
  }

  void _initEncounter() {
    _maxEnergy = widget.runController.state.energyPerTurn;
    _currentEnergy = _maxEnergy;

    if (widget.node.type == NodeType.boss) {
      _enemyHp = 120;
      _maxEnemyHp = 120;
    } else if (widget.node.type == NodeType.elite) {
      _enemyHp = 80;
      _maxEnemyHp = 80;
    }

    // Generate elemental board
    var board = HexBoard.hexagonal(radius: 2);

    // Apply active relic modifications
    for (final relic in widget.runController.state.relics) {
      if (relic.criticalMassReduction > 0) {
        board = HexBoard(
          cells: board.cells,
          criticalMassOffset: -relic.criticalMassReduction,
        );
      }
    }

    // Add elemental portals / cryo / magma
    final Map<HexCoord, HexCell> cells = Map<HexCoord, HexCell>.from(board.cells);
    const p1 = HexCoord(1, -1);
    const p2 = HexCoord(-1, 1);
    if (cells.containsKey(p1) && cells.containsKey(p2)) {
      cells[p1] = cells[p1]!.copyWith(tileType: TileType.portal, portalTarget: p2);
      cells[p2] = cells[p2]!.copyWith(tileType: TileType.portal, portalTarget: p1);
    }

    const cryo = HexCoord(0, 1);
    if (cells.containsKey(cryo)) {
      cells[cryo] = cells[cryo]!.copyWith(tileType: TileType.cryo);
    }

    const magma = HexCoord(0, -1);
    if (cells.containsKey(magma)) {
      cells[magma] = cells[magma]!.copyWith(tileType: TileType.magma);
    }

    _board = HexBoard(cells: cells, criticalMassOffset: board.criticalMassOffset);
  }

  void _onHexTapped(HexCoord coord) async {
    if (!_isPlayerTurn || _isResolvingCascade || _currentEnergy <= 0) return;
    if (!_engine.canPlace(_board, coord, _humanId)) return;

    setState(() {
      _currentEnergy--;
      _isResolvingCascade = true;
    });

    TacticalAudio.playOrbPlace();

    final result = _engine.applyMove(_board, coord, _humanId);
    await _animateWaves(result);

    // Damage enemy based on cascade explosions
    if (result.waves.isNotEmpty) {
      final damage = result.waves.length * 15;
      setState(() {
        _enemyHp = (_enemyHp - damage).clamp(0, _maxEnemyHp);
      });
    }

    if (_enemyHp <= 0) {
      _handleCombatVictory();
      return;
    }

    setState(() {
      _isResolvingCascade = false;
    });

    if (_currentEnergy <= 0) {
      _endPlayerTurn();
    }
  }

  void _endPlayerTurn() async {
    setState(() {
      _isPlayerTurn = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // AI Turn execution
    if (_enemyHp > 0) {
      final aiMove = _ai.selectMove(_board, _aiId, _humanId);
      if (aiMove != null && mounted) {
        final result = _engine.applyMove(_board, aiMove, _aiId);
        await _animateWaves(result);

        if (result.waves.isNotEmpty) {
          widget.runController.takeDamage(result.waves.length * 8);
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentEnergy = _maxEnergy;
        _isPlayerTurn = true;
      });
    }
  }

  Future<void> _animateWaves(HexMoveResult result) async {
    for (int i = 0; i < result.frames.length; i++) {
      setState(() {
        _board = result.frames[i];
      });
      if (i > 0) {
        TacticalAudio.playWaveCascade(i - 1);
      }
      await Future.delayed(const Duration(milliseconds: 320));
    }
  }

  void _handleCombatVictory() {
    TacticalAudio.playVictory();
    widget.runController.addShards(35);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.surface,
        title: const Text('🎉 Sector Cleared!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('You earned +35 Aether Shards from defeating ${widget.node.title}!'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TacticalTheme.playerHero),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Return to sector map
            },
            child: const Text('Continue Expedition', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TacticalTheme.background,
      appBar: AppBar(
        backgroundColor: TacticalTheme.surface,
        title: Text('${widget.node.icon} ${widget.node.title}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '⚡ Energy: $_currentEnergy/$_maxEnergy',
                style: const TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.teslaGold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // HP Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: TacticalTheme.surface.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HERO', style: TextStyle(color: TacticalTheme.playerHero, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${widget.runController.state.heroHp}/${widget.runController.state.maxHeroHp} HP',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ENEMY: ${widget.node.title.toUpperCase()}',
                        style: const TextStyle(color: TacticalTheme.playerEnemy, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('$_enemyHp/$_maxEnemyHp HP',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),

          // Interactive GPU Hex Battlefield
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final center = Offset(constraints.maxWidth / 2.0, constraints.maxHeight / 2.0);
                  final radius = (constraints.maxWidth / 7.5).clamp(28.0, 52.0);
                  final layout = HexLayout(radius: radius, origin: center);

                  return GestureDetector(
                    onTapUp: (details) {
                      final hex = layout.pixelToHex(details.localPosition);
                      if (_board.contains(hex)) {
                        _onHexTapped(hex);
                      }
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: HexBoardPainter(
                        board: _board,
                        layout: layout,
                        humanPlayerId: _humanId,
                        hoveredCoord: _hoveredCoord,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Controls & End Turn Button
          Container(
            padding: const EdgeInsets.all(16),
            color: TacticalTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPlayerTurn ? '👉 Tap an empty or owned hex' : '⏳ Enemy thinking...',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlayerTurn ? TacticalTheme.playerHero : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: (_isPlayerTurn && !_isResolvingCascade) ? _endPlayerTurn : null,
                  icon: const Icon(Icons.skip_next, color: Colors.black),
                  label: const Text('End Turn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
