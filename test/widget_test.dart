import 'package:flutter_test/flutter_test.dart';
import 'package:chain_grid_tactics/main.dart';

void main() {
  testWidgets('Chain Grid Tactics main menu smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChainGridTacticsApp());
    await tester.pumpAndSettle();

    expect(find.text('CHAIN GRID'), findsOneWidget);
    expect(find.text('TACTICS'), findsOneWidget);
    expect(find.text('⚔️ START EXPEDITION'), findsOneWidget);
  });
}
