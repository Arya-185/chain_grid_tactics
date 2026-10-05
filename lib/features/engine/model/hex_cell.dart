import 'package:flutter/foundation.dart';
import '../../../core/geometry/hex_coord.dart';

/// The elemental or structural variant of a hex tile.
enum TileType {
  normal,      // Standard territory cell
  cryo,        // Frozen ice cell (absorbs 1 blast wave, melts to normal)
  magma,       // Lava cell (explodes with double damage / extra wave reach)
  portal,      // Wormhole portal (transfers shockwave to paired portal)
  tesla,       // Electric conduit (arcs to enemy near-critical cell)
  ruin,        // Destructible stone barrier (blocks blast until HP = 0)
}

/// Immutable state of an individual hexagonal cell on the board.
@immutable
class HexCell {
  const HexCell({
    required this.coord,
    this.orbs = 0,
    this.ownerId,
    this.tileType = TileType.normal,
    this.barrierHp = 0,
    this.portalTarget,
  });

  final HexCoord coord;
  final int orbs;
  final int? ownerId;
  final TileType tileType;
  final int barrierHp;
  final HexCoord? portalTarget;

  bool get isEmpty => orbs == 0 && barrierHp == 0;
  bool get hasBarrier => barrierHp > 0;
  bool get isFrozen => tileType == TileType.cryo;
  bool get isPortal => tileType == TileType.portal;

  HexCell copyWith({
    HexCoord? coord,
    int? orbs,
    int? ownerId,
    bool clearOwner = false,
    TileType? tileType,
    int? barrierHp,
    HexCoord? portalTarget,
  }) {
    return HexCell(
      coord: coord ?? this.coord,
      orbs: orbs ?? this.orbs,
      ownerId: clearOwner ? null : (ownerId ?? this.ownerId),
      tileType: tileType ?? this.tileType,
      barrierHp: barrierHp ?? this.barrierHp,
      portalTarget: portalTarget ?? this.portalTarget,
    );
  }

  factory HexCell.fromJson(Map<String, dynamic> json) {
    return HexCell(
      coord: HexCoord.fromJson(json['coord'] as Map<String, dynamic>),
      orbs: json['orbs'] as int? ?? 0,
      ownerId: json['ownerId'] as int?,
      tileType: TileType.values.byName(json['tileType'] as String? ?? 'normal'),
      barrierHp: json['barrierHp'] as int? ?? 0,
      portalTarget: json['portalTarget'] != null
          ? HexCoord.fromJson(json['portalTarget'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'coord': coord.toJson(),
    'orbs': orbs,
    'ownerId': ownerId,
    'tileType': tileType.name,
    'barrierHp': barrierHp,
    'portalTarget': portalTarget?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HexCell &&
          other.coord == coord &&
          other.orbs == orbs &&
          other.ownerId == ownerId &&
          other.tileType == tileType &&
          other.barrierHp == barrierHp &&
          other.portalTarget == portalTarget);

  @override
  int get hashCode => Object.hash(coord, orbs, ownerId, tileType, barrierHp, portalTarget);
}
