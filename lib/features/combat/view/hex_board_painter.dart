import 'package:flutter/material.dart';
import '../../../core/geometry/hex_coord.dart';
import '../../../core/geometry/hex_layout.dart';
import '../../../core/theme/tactical_theme.dart';
import '../../engine/model/hex_board.dart';
import '../../engine/model/hex_cell.dart';

/// High performance GPU CustomPainter for drawing the interactive hex grid and orbs.
class HexBoardPainter extends CustomPainter {
  HexBoardPainter({
    required this.board,
    required this.layout,
    required this.humanPlayerId,
    this.hoveredCoord,
    this.hintedCoord,
  });

  final HexBoard board;
  final HexLayout layout;
  final int humanPlayerId;
  final HexCoord? hoveredCoord;
  final HexCoord? hintedCoord;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw all hex tiles
    for (final cell in board.cells.values) {
      _drawHexCell(canvas, cell);
    }
  }

  void _drawHexCell(Canvas canvas, HexCell cell) {
    final center = layout.hexToPixel(cell.coord);
    final vertices = cell.coord.polygonVertices(
      layout.radius,
      pointy: layout.pointy,
      origin: layout.origin,
    );

    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    // Base fill color
    Color fillColor = TacticalTheme.surface;
    Color strokeColor = TacticalTheme.surfaceLight;

    if (cell.tileType == TileType.cryo) {
      fillColor = TacticalTheme.cryoIce.withValues(alpha: 0.25);
      strokeColor = TacticalTheme.cryoIce;
    } else if (cell.tileType == TileType.magma) {
      fillColor = TacticalTheme.magmaLava.withValues(alpha: 0.25);
      strokeColor = TacticalTheme.magmaLava;
    } else if (cell.tileType == TileType.portal) {
      fillColor = TacticalTheme.portalViolet.withValues(alpha: 0.35);
      strokeColor = TacticalTheme.portalViolet;
    } else if (cell.hasBarrier) {
      fillColor = TacticalTheme.stoneRuin.withValues(alpha: 0.4);
      strokeColor = TacticalTheme.stoneRuin;
    }

    if (hoveredCoord == cell.coord) {
      fillColor = fillColor.withValues(alpha: 0.6);
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (hoveredCoord == cell.coord) ? 2.5 : 1.2;

    canvas.drawPath(path, strokePaint);

    // Draw Barrier HP indicator
    if (cell.hasBarrier) {
      _drawCenteredText(canvas, center, '🛡️${cell.barrierHp}', 11, Colors.white70);
      return;
    }

    // Draw Portal glyph
    if (cell.isPortal) {
      _drawCenteredText(canvas, center.translate(0, -layout.radius * 0.4), '🌀', 12, Colors.white);
    }

    // 2. Draw orbs inside the cell
    if (cell.orbs > 0) {
      _drawOrbs(canvas, cell, center);
    }
  }

  void _drawOrbs(Canvas canvas, HexCell cell, Offset center) {
    final orbColor = (cell.ownerId == humanPlayerId)
        ? TacticalTheme.playerHero
        : TacticalTheme.playerEnemy;

    final critMass = board.criticalMassOf(cell.coord);
    final isCritical = cell.orbs >= critMass - 1;

    // Glowing critical ring
    if (isCritical) {
      final glowPaint = Paint()
        ..color = orbColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(center, layout.radius * 0.65, glowPaint);
    }

    final orbRadius = layout.radius * 0.18;
    final orbPaint = Paint()
      ..color = orbColor
      ..style = PaintingStyle.fill;

    if (cell.orbs == 1) {
      canvas.drawCircle(center, orbRadius * 1.2, orbPaint);
    } else if (cell.orbs == 2) {
      final offset = layout.radius * 0.28;
      canvas.drawCircle(center.translate(-offset, 0), orbRadius, orbPaint);
      canvas.drawCircle(center.translate(offset, 0), orbRadius, orbPaint);
    } else if (cell.orbs == 3) {
      final offset = layout.radius * 0.3;
      canvas.drawCircle(center.translate(0, -offset), orbRadius, orbPaint);
      canvas.drawCircle(center.translate(-offset * 0.86, offset * 0.5), orbRadius, orbPaint);
      canvas.drawCircle(center.translate(offset * 0.86, offset * 0.5), orbRadius, orbPaint);
    } else {
      // 4 or more orbs: Draw central orb with counter
      canvas.drawCircle(center, orbRadius * 1.5, orbPaint);
      _drawCenteredText(canvas, center, '${cell.orbs}', 13, Colors.black87, bold: true);
    }
  }

  void _drawCenteredText(Canvas canvas, Offset center, String text, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2.0, -tp.height / 2.0));
  }

  @override
  bool shouldRepaint(covariant HexBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.hoveredCoord != hoveredCoord ||
        oldDelegate.hintedCoord != hintedCoord;
  }
}
