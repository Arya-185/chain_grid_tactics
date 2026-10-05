import 'package:flutter/foundation.dart';

/// A draftable passive artifact altering tactical rules during a run.
@immutable
class Relic {
  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.criticalMassReduction = 0,
    this.bonusEnergy = 0,
    this.cryoShieldOnTurn = false,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int criticalMassReduction;
  final int bonusEnergy;
  final bool cryoShieldOnTurn;

  /// Curated catalog of game-changing relics.
  static const List<Relic> catalog = [
    Relic(
      id: 'chain_magnet',
      name: 'Chain Magnet',
      description: 'Reduces the critical mass of all cells by 1 (triggers faster cascades).',
      icon: '🧲',
      criticalMassReduction: 1,
    ),
    Relic(
      id: 'aether_battery',
      name: 'Aether Battery',
      description: 'Grants +1 Max Energy point per turn.',
      icon: '🔋',
      bonusEnergy: 1,
    ),
    Relic(
      id: 'glacial_bastion',
      name: 'Glacial Bastion',
      description: 'Your first move in each battle places a Cryo Frost shield on adjacent cells.',
      icon: '🛡️',
      cryoShieldOnTurn: true,
    ),
    Relic(
      id: 'molten_core',
      name: 'Molten Core',
      description: 'When you trigger an explosion wave of >= 4 cells, ignite a random enemy hex.',
      icon: '🔥',
    ),
    Relic(
      id: 'quantum_prism',
      name: 'Quantum Prism',
      description: 'Start every encounter with a pair of connected Wormhole Portals.',
      icon: '🌀',
    ),
  ];
}
