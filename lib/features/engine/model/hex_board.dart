import 'package:flutter/foundation.dart';
import '../../../core/geometry/hex_coord.dart';
import 'hex_cell.dart';

/// Immutable representation of the hex battlefield.
/// Uses a sparse `Map<HexCoord, HexCell>` enabling irregular procedural dungeons and arena layouts.
@immutable
class HexBoard {
  const HexBoard({
    required this.cells,
    this.criticalMassOffset = 0,
  });

  final Map<HexCoord, HexCell> cells;

  /// Global modifier (e.g. from relics like 'Chain Magnet' reducing mass by 1).
  final int criticalMassOffset;

  /// Creates a regular hexagonal grid of given radius centered at (0, 0).
  factory HexBoard.hexagonal({int radius = 3, int criticalMassOffset = 0}) {
    final Map<HexCoord, HexCell> map = {};
    for (int q = -radius; q <= radius; q++) {
      final r1 = (-radius).clamp(-radius - q, radius);
      final r2 = radius.clamp(-radius, radius - q);
      for (int r = r1; r <= r2; r++) {
        final coord = HexCoord(q, r);
        map[coord] = HexCell(coord: coord);
      }
    }
    return HexBoard(cells: map, criticalMassOffset: criticalMassOffset);
  }

  /// Calculates the dynamic critical mass for a cell based on active board neighbors.
  int criticalMassOf(HexCoord coord) {
    int validNeighbors = 0;
    for (final neighbor in coord.allNeighbors()) {
      if (cells.containsKey(neighbor)) {
        validNeighbors++;
      }
    }
    final mass = validNeighbors + criticalMassOffset;
    return mass.clamp(2, 6);
  }

  /// All valid neighbors of a cell that are currently part of this board.
  List<HexCoord> validNeighborsOf(HexCoord coord) {
    return coord.allNeighbors().where((n) => cells.containsKey(n)).toList();
  }

  /// Checks if a coordinate is within the board.
  bool contains(HexCoord coord) => cells.containsKey(coord);

  HexCell? cellAt(HexCoord coord) => cells[coord];

  HexBoard withCell(HexCell cell) {
    final newCells = Map<HexCoord, HexCell>.from(cells);
    newCells[cell.coord] = cell;
    return HexBoard(cells: newCells, criticalMassOffset: criticalMassOffset);
  }

  HexBoard withCells(Iterable<HexCell> updatedCells) {
    final newCells = Map<HexCoord, HexCell>.from(cells);
    for (final c in updatedCells) {
      newCells[c.coord] = c;
    }
    return HexBoard(cells: newCells, criticalMassOffset: criticalMassOffset);
  }

  /// Total count of orbs on the board owned by a specific player.
  int orbsForPlayer(int playerId) {
    int total = 0;
    for (final cell in cells.values) {
      if (cell.ownerId == playerId) {
        total += cell.orbs;
      }
    }
    return total;
  }

  /// Returns all cells owned by a specific player.
  List<HexCell> cellsForPlayer(int playerId) {
    return cells.values.where((c) => c.ownerId == playerId).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HexBoard &&
          mapEquals(other.cells, cells) &&
          other.criticalMassOffset == criticalMassOffset);

  @override
  int get hashCode => Object.hash(Object.hashAll(cells.entries), criticalMassOffset);
}
