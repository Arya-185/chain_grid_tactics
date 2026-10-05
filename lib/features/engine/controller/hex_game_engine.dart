import '../../../core/geometry/hex_coord.dart';
import '../model/hex_board.dart';
import '../model/hex_cell.dart';
import '../model/hex_wave_event.dart';

/// Pure, stateless rules engine for Hexagonal Chain Reactions and Elemental Interactions.
class HexGameEngine {
  const HexGameEngine();

  /// Whether a player is legally allowed to place an orb on [coord].
  bool canPlace(HexBoard board, HexCoord coord, int playerId) {
    final cell = board.cellAt(coord);
    if (cell == null) return false;
    // Cannot place directly on stone ruins / barriers
    if (cell.hasBarrier) return false;
    // Empty cells or cells already owned by the player are legal
    return cell.ownerId == null || cell.ownerId == playerId;
  }

  /// All legal coordinates where [playerId] can place an orb.
  List<HexCoord> legalMoves(HexBoard board, int playerId) {
    return board.cells.values
        .where((cell) => !cell.hasBarrier && (cell.ownerId == null || cell.ownerId == playerId))
        .map((cell) => cell.coord)
        .toList();
  }

  /// Applies a move at [coord] by [playerId], resolving any resulting explosion cascade waves.
  HexMoveResult applyMove(HexBoard initialBoard, HexCoord coord, int playerId) {
    if (!canPlace(initialBoard, coord, playerId)) {
      throw ArgumentError('Illegal move at $coord by player $playerId');
    }

    final initialCell = initialBoard.cellAt(coord)!;
    var currentBoard = initialBoard.withCell(
      initialCell.copyWith(
        orbs: initialCell.orbs + 1,
        ownerId: playerId,
      ),
    );

    final List<HexBoard> frames = [currentBoard];
    final List<HexExplosionWave> waves = [];

    // Continuous wave resolution loop
    int safetyLimit = 300; // Guard against infinite cascade oscillation
    while (safetyLimit-- > 0) {
      final List<HexCell> explodingCells = [];
      for (final cell in currentBoard.cells.values) {
        if (cell.orbs >= currentBoard.criticalMassOf(cell.coord)) {
          explodingCells.add(cell);
        }
      }

      if (explodingCells.isEmpty) break;

      final List<HexExplosionEvent> waveEvents = [];
      final Map<HexCoord, HexCell> nextCells = Map.from(currentBoard.cells);

      for (final cell in explodingCells) {
        final rawTargets = currentBoard.validNeighborsOf(cell.coord);
        final Map<HexCoord, HexCoord> portalMap = {};
        final List<HexCoord> finalTargets = [];

        for (final targetCoord in rawTargets) {
          final targetCell = currentBoard.cellAt(targetCoord);
          if (targetCell != null && targetCell.isPortal && targetCell.portalTarget != null) {
            portalMap[targetCoord] = targetCell.portalTarget!;
            finalTargets.add(targetCell.portalTarget!);
          } else {
            finalTargets.add(targetCoord);
          }
        }

        waveEvents.add(HexExplosionEvent(
          from: cell.coord,
          moverId: cell.ownerId ?? playerId,
          targets: finalTargets,
          tileType: cell.tileType,
          portalDestinations: portalMap,
        ));

        // Source cell orbs detonate: reduce by critical mass
        final critMass = currentBoard.criticalMassOf(cell.coord);
        final remainingOrbs = cell.orbs - critMass;
        nextCells[cell.coord] = cell.copyWith(
          orbs: remainingOrbs,
          clearOwner: remainingOrbs == 0,
        );
      }

      // Distribute projectile orbs to destination targets
      for (final event in waveEvents) {
        for (final targetCoord in event.targets) {
          final target = nextCells[targetCoord];
          if (target == null) continue;

          // 1. Destructible Ruin Barrier absorbs blast
          if (target.hasBarrier) {
            final newHp = target.barrierHp - 1;
            nextCells[targetCoord] = target.copyWith(barrierHp: newHp);
            continue;
          }

          // 2. Cryo Ice Cell absorbs 1 blast and melts to normal
          if (target.tileType == TileType.cryo) {
            nextCells[targetCoord] = target.copyWith(tileType: TileType.normal);
            continue;
          }

          // 3. Magma tile: add 2 orbs if ignited by magma
          final incomingOrbs = (event.tileType == TileType.magma || target.tileType == TileType.magma) ? 2 : 1;

          nextCells[targetCoord] = target.copyWith(
            orbs: target.orbs + incomingOrbs,
            ownerId: event.moverId,
          );
        }
      }

      currentBoard = HexBoard(
        cells: nextCells,
        criticalMassOffset: currentBoard.criticalMassOffset,
      );
      waves.add(HexExplosionWave(events: waveEvents));
      frames.add(currentBoard);
    }

    return HexMoveResult(
      finalBoard: currentBoard,
      frames: frames,
      waves: waves,
      moverId: playerId,
      originCoord: coord,
    );
  }
}
