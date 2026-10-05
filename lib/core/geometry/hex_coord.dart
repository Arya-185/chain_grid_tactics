import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An immutable hexagonal coordinate in axial (q, r) representation.
/// The implicit third cubic coordinate is s = -q - r, satisfying q + r + s = 0.
@immutable
class HexCoord {
  const HexCoord(this.q, this.r);

  final int q;
  final int r;
  int get s => -q - r;

  /// The 6 direct neighbor vectors in axial coordinates.
  /// Order: East, North-East, North-West, West, South-West, South-East.
  static const List<HexCoord> directions = [
    HexCoord(1, 0),   // East
    HexCoord(1, -1),  // North-East
    HexCoord(0, -1),  // North-West
    HexCoord(-1, 0),  // West
    HexCoord(-1, 1),  // South-West
    HexCoord(0, 1),   // South-East
  ];

  HexCoord operator +(HexCoord other) => HexCoord(q + other.q, r + other.r);
  HexCoord operator -(HexCoord other) => HexCoord(q - other.q, r - other.r);
  HexCoord operator *(int scalar) => HexCoord(q * scalar, r * scalar);

  HexCoord neighbor(int directionIndex) {
    assert(directionIndex >= 0 && directionIndex < 6);
    return this + directions[directionIndex];
  }

  List<HexCoord> allNeighbors() => directions.map((d) => this + d).toList();

  /// Manhattan distance in hex coordinate space.
  int distanceTo(HexCoord other) {
    final dq = (q - other.q).abs();
    final dr = (r - other.r).abs();
    final ds = (s - other.s).abs();
    return ((dq + dr + ds) / 2).round();
  }

  /// Converts axial (q, r) into 2D Cartesian offset (pointy-topped hexagon).
  Offset toPixelPointy(double radius, [Offset origin = Offset.zero]) {
    final x = radius * math.sqrt(3) * (q + r / 2.0) + origin.dx;
    final y = radius * (3.0 / 2.0) * r + origin.dy;
    return Offset(x, y);
  }

  /// Converts axial (q, r) into 2D Cartesian offset (flat-topped hexagon).
  Offset toPixelFlat(double radius, [Offset origin = Offset.zero]) {
    final x = radius * (3.0 / 2.0) * q + origin.dx;
    final y = radius * math.sqrt(3) * (r + q / 2.0) + origin.dy;
    return Offset(x, y);
  }

  /// Calculates the 6 polygon corner vertices for this cell.
  List<Offset> polygonVertices(double radius, {bool pointy = true, Offset origin = Offset.zero}) {
    final center = pointy ? toPixelPointy(radius, origin) : toPixelFlat(radius, origin);
    final List<Offset> vertices = [];
    final angleOffset = pointy ? math.pi / 6.0 : 0.0;

    for (int i = 0; i < 6; i++) {
      final angle = angleOffset + (i * math.pi / 3.0);
      vertices.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }
    return vertices;
  }

  /// Factory from raw JSON map.
  factory HexCoord.fromJson(Map<String, dynamic> json) =>
      HexCoord(json['q'] as int, json['r'] as int);

  Map<String, dynamic> toJson() => {'q': q, 'r': r};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is HexCoord && other.q == q && other.r == r);

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'HexCoord($q, $r)';
}
