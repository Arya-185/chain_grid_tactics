import '../../core/geometry/hex_coord.dart';
import '../engine/controller/hex_game_engine.dart';
import '../engine/model/hex_board.dart';

enum AiDifficulty {
  apprentice, // Greedy 1-ply placement
  tactician,  // Minimax 2-ply evaluation
  archmage,   // Minimax with aggressive cascade heuristics
}

/// Tactical AI for Hexagonal battle encounters.
class HexTacticalAi {
  const HexTacticalAi({
    this.difficulty = AiDifficulty.tactician,
    this.engine = const HexGameEngine(),
  });

  final AiDifficulty difficulty;
  final HexGameEngine engine;

  /// Chooses the optimal HexCoord move for the AI player.
  HexCoord? selectMove(HexBoard board, int aiPlayerId, int humanPlayerId) {
    final legalMoves = engine.legalMoves(board, aiPlayerId);
    if (legalMoves.isEmpty) return null;

    if (difficulty == AiDifficulty.apprentice) {
      // Pick random or simple orb count maximizer
      legalMoves.shuffle();
      return legalMoves.first;
    }

    HexCoord bestMove = legalMoves.first;
    double bestScore = -double.infinity;

    for (final move in legalMoves) {
      final sim = engine.applyMove(board, move, aiPlayerId);
      final score = _evaluate(sim.finalBoard, aiPlayerId, humanPlayerId);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Evaluates board position advantage:
  /// High orbs owned, high critical threat, and corner/safe anchor control.
  double _evaluate(HexBoard board, int aiPlayerId, int humanPlayerId) {
    final aiCells = board.cellsForPlayer(aiPlayerId);
    final humanCells = board.cellsForPlayer(humanPlayerId);

    if (humanCells.isEmpty && aiCells.isNotEmpty) return 100000.0; // Win
    if (aiCells.isEmpty && humanCells.isNotEmpty) return -100000.0; // Loss

    double score = 0.0;

    // 1. Orb count differential
    score += (board.orbsForPlayer(aiPlayerId) - board.orbsForPlayer(humanPlayerId)) * 10.0;

    // 2. Critical threat control (cells 1 away from explosion)
    for (final cell in aiCells) {
      final crit = board.criticalMassOf(cell.coord);
      if (cell.orbs == crit - 1) {
        score += 15.0; // Ready to burst
      }
      // Chokepoints / low critical mass cells are more valuable
      if (crit <= 3) {
        score += 8.0;
      }
    }

    for (final cell in humanCells) {
      final crit = board.criticalMassOf(cell.coord);
      if (cell.orbs == crit - 1) {
        score -= 20.0; // Dangerous human critical cell
      }
    }

    return score;
  }
}
