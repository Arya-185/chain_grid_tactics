import 'package:flutter_test/flutter_test.dart';
import 'package:chain_grid_tactics/core/geometry/hex_coord.dart';
import 'package:chain_grid_tactics/core/geometry/hex_layout.dart';
import 'package:chain_grid_tactics/features/engine/controller/hex_game_engine.dart';
import 'package:chain_grid_tactics/features/engine/model/hex_board.dart';
import 'package:chain_grid_tactics/features/engine/model/hex_cell.dart';

void main() {
  group('Hex Geometry & Math', () {
    test('axial coordinate cubic constraint q + r + s == 0', () {
      const c = HexCoord(2, -3);
      expect(c.s, 1);
      expect(c.q + c.r + c.s, 0);
    });

    test('6 distinct neighbors generated properly', () {
      const origin = HexCoord(0, 0);
      final neighbors = origin.allNeighbors();
      expect(neighbors.length, 6);
      expect(neighbors.contains(const HexCoord(1, 0)), isTrue);
      expect(neighbors.contains(const HexCoord(-1, 1)), isTrue);
    });

    test('Hex distance calculation', () {
      const a = HexCoord(0, 0);
      const b = HexCoord(2, -2);
      expect(a.distanceTo(b), 2);
    });

    test('HexLayout round-trip hit testing', () {
      const layout = HexLayout(radius: 30.0);
      const original = HexCoord(3, -2);
      final pixel = layout.hexToPixel(original);
      final backToHex = layout.pixelToHex(pixel);
      expect(backToHex, original);
    });
  });

  group('Pure HexGameEngine & Physics', () {
    const engine = HexGameEngine();

    test('Initial placement sets orb and owner', () {
      final board = HexBoard.hexagonal(radius: 2);
      const target = HexCoord(0, 0);
      expect(engine.canPlace(board, target, 1), isTrue);

      final result = engine.applyMove(board, target, 1);
      expect(result.finalBoard.cellAt(target)?.orbs, 1);
      expect(result.finalBoard.cellAt(target)?.ownerId, 1);
      expect(result.waves.isEmpty, isTrue);
    });

    test('Cell detonates upon reaching critical mass', () {
      var board = HexBoard.hexagonal(radius: 1);
      const center = HexCoord(0, 0);
      final critMass = board.criticalMassOf(center);
      expect(critMass, 6); // Surrounded by 6 neighbors

      // Stage cell with 5 orbs
      board = board.withCell(HexCell(coord: center, orbs: 5, ownerId: 1));

      // 6th orb triggers explosion
      final result = engine.applyMove(board, center, 1);
      expect(result.waves.isNotEmpty, isTrue);
      expect(result.finalBoard.cellAt(center)?.orbs, 0);

      // All 6 neighbors received 1 orb
      for (final neighbor in center.allNeighbors()) {
        expect(result.finalBoard.cellAt(neighbor)?.orbs, 1);
        expect(result.finalBoard.cellAt(neighbor)?.ownerId, 1);
      }
    });

    test('Cryo Ice cell absorbs explosion and converts to normal', () {
      var board = HexBoard.hexagonal(radius: 1);
      const center = HexCoord(0, 0);
      const iceCoord = HexCoord(1, 0);

      board = board.withCell(const HexCell(coord: iceCoord, tileType: TileType.cryo));
      board = board.withCell(const HexCell(coord: center, orbs: 5, ownerId: 1));

      final result = engine.applyMove(board, center, 1);
      final iceResult = result.finalBoard.cellAt(iceCoord);

      expect(iceResult?.tileType, TileType.normal);
      expect(iceResult?.orbs, 0); // absorbed, did not gain orb
    });

    test('Wormhole portal teleports blast shockwave', () {
      var board = HexBoard.hexagonal(radius: 2);
      const center = HexCoord(0, 0);
      const portalA = HexCoord(1, 0);
      const portalB = HexCoord(-2, 2);

      board = board.withCell(const HexCell(coord: portalA, tileType: TileType.portal, portalTarget: portalB));
      board = board.withCell(const HexCell(coord: portalB, tileType: TileType.portal, portalTarget: portalA));
      board = board.withCell(const HexCell(coord: center, orbs: 5, ownerId: 1));

      final result = engine.applyMove(board, center, 1);
      // Portal B received the teleported blast
      expect(result.finalBoard.cellAt(portalB)?.orbs, greaterThan(0));
    });
  });
}
