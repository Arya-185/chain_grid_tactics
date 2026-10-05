import 'package:flutter/material.dart';
import 'core/firebase/firebase_bridge.dart';
import 'core/theme/tactical_theme.dart';
import 'features/roguelike/controller/run_controller.dart';
import 'features/roguelike/view/sector_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseTacticsBridge.initialize();

  runApp(const ChainGridTacticsApp());
}

class ChainGridTacticsApp extends StatelessWidget {
  const ChainGridTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chain Grid: Tactics',
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.darkTheme,
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final RunController _runController = RunController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TacticalTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Title Emblem
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: TacticalTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: TacticalTheme.playerHero, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: TacticalTheme.playerHero.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💥', style: TextStyle(fontSize: 42)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CHAIN GRID',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'TACTICS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6.0,
                    color: TacticalTheme.playerHero,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hexagonal Elemental Roguelike',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 48),

                // Main Action Buttons
                _buildMenuButton(
                  title: '⚔️ START EXPEDITION',
                  color: TacticalTheme.playerHero,
                  textColor: Colors.black,
                  onPressed: () {
                    _runController.resetRun();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectorMapScreen(runController: _runController),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  title: '📖 HOW TO PLAY',
                  color: TacticalTheme.surface,
                  textColor: Colors.white,
                  onPressed: () => _showHowToPlayDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.surface,
        title: const Text('📖 Rules & Elements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Hexagonal Mechanics:', style: TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.playerHero)),
              Text('Cells have up to 6 neighbors. When orbs reach neighbor count, the cell detonates into all 6 adjacent hexes!\n', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text('• Elemental Tiles:', style: TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.magmaLava)),
              Text('❄️ Cryo Ice: Absorbs shockwaves by melting.\n🔥 Magma: Superheats orbs with double impact.\n🌀 Portals: Instantly teleport projectile shockwaves across the board!\n', style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text('• Roguelike Loop:', style: TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.teslaGold)),
              Text('Traverse sector nodes, defeat enemies, draft relics to alter game physics, and defeat the Sector Archmage.', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: TacticalTheme.playerHero)),
          ),
        ],
      ),
    );
  }
}
