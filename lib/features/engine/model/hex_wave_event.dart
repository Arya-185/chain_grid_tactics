import 'package:flutter/foundation.dart';
import '../../../core/geometry/hex_coord.dart';
import 'hex_cell.dart';

/// Represents a single burst event from a source cell to target cells.
@immutable
class HexExplosionEvent {
  const HexExplosionEvent({
    required this.from,
    required this.moverId,
    required this.targets,
    required this.tileType,
    this.portalDestinations = const {},
  });

  final HexCoord from;
  final int moverId;
  final List<HexCoord> targets;
  final TileType tileType;

  /// If a target is a portal, maps that target to the exit portal coordinate.
  final Map<HexCoord, HexCoord> portalDestinations;
}

/// Represents all explosions occurring concurrently in a single cascade wave layer.
@immutable
class HexExplosionWave {
  const HexExplosionWave({required this.events});
  final List<HexExplosionEvent> events;

  bool get isEmpty => events.isEmpty;
  bool get isNotEmpty => events.isNotEmpty;
}

/// Detailed result of executing a move, containing step-by-step frames for animation.
@immutable
class HexMoveResult {
  const HexMoveResult({
    required this.finalBoard,
    required this.frames,
    required this.waves,
    required this.moverId,
    required this.originCoord,
    this.eliminatedPlayerIds = const [],
  });

  final dynamic finalBoard; // HexBoard
  final List<dynamic> frames; // List<HexBoard>
  final List<HexExplosionWave> waves;
  final int moverId;
  final HexCoord originCoord;
  final List<int> eliminatedPlayerIds;

  int get totalWaves => waves.length;
}
