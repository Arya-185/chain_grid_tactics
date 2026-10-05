import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hex_coord.dart';

/// Handles bidirectional conversion between 2D screen pixels and discrete Hex coordinates.
class HexLayout {
  const HexLayout({
    required this.radius,
    this.origin = Offset.zero,
    this.pointy = true,
  });

  final double radius;
  final Offset origin;
  final bool pointy;

  /// Gets the exact pixel center for a given hex.
  Offset hexToPixel(HexCoord hex) =>
      pointy ? hex.toPixelPointy(radius, origin) : hex.toPixelFlat(radius, origin);

  /// Performs pixel-to-hex hit-testing using fractional axial rounding.
  HexCoord pixelToHex(Offset point) {
    final pt = point - origin;
    double fracQ, fracR;

    if (pointy) {
      fracQ = (math.sqrt(3) / 3.0 * pt.dx - 1.0 / 3.0 * pt.dy) / radius;
      fracR = (2.0 / 3.0 * pt.dy) / radius;
    } else {
      fracQ = (2.0 / 3.0 * pt.dx) / radius;
      fracR = (-1.0 / 3.0 * pt.dx + math.sqrt(3) / 3.0 * pt.dy) / radius;
    }

    return _roundHex(fracQ, fracR);
  }

  /// Cube rounding algorithm to snap fractional coordinates to the nearest hex.
  HexCoord _roundHex(double fracQ, double fracR) {
    final fracS = -fracQ - fracR;

    int q = fracQ.round();
    int r = fracR.round();
    int s = fracS.round();

    final qDiff = (q - fracQ).abs();
    final rDiff = (r - fracR).abs();
    final sDiff = (s - fracS).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      q = -r - s;
    } else if (rDiff > sDiff) {
      r = -q - s;
    }

    return HexCoord(q, r);
  }
}
