import 'package:flutter/foundation.dart';

/// Permanent meta-progression traits unlocked with Aether Shards.
@immutable
class TechUpgrade {
  const TechUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    this.unlocked = false,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final String icon;
  final bool unlocked;

  TechUpgrade copyWith({bool? unlocked}) {
    return TechUpgrade(
      id: id,
      name: name,
      description: description,
      cost: cost,
      icon: icon,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  static const List<TechUpgrade> defaultTree = [
    TechUpgrade(
      id: 'vitality_boost',
      name: 'Vitality Matrix',
      description: 'Increases hero starting health by +25 HP.',
      cost: 50,
      icon: '💖',
    ),
    TechUpgrade(
      id: 'starting_energy',
      name: 'Aether Conduit',
      description: 'Start every battle with +1 extra Energy.',
      cost: 100,
      icon: '⚡',
    ),
    TechUpgrade(
      id: 'portal_attunement',
      name: 'Rift Walker',
      description: 'Orbs teleporting through portals gain +1 extra orb upon exit.',
      cost: 150,
      icon: '🌀',
    ),
  ];
}
