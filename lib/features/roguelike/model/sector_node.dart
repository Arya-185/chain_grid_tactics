import 'package:flutter/foundation.dart';

enum NodeType {
  combat,
  elite,
  shrine,
  merchant,
  mystery,
  boss,
}

@immutable
class SectorNode {
  const SectorNode({
    required this.id,
    required this.depth,
    required this.index,
    required this.type,
    required this.title,
    this.completed = false,
    this.nextIndices = const [],
  });

  final String id;
  final int depth;
  final int index;
  final NodeType type;
  final String title;
  final bool completed;
  final List<int> nextIndices;

  String get icon {
    switch (type) {
      case NodeType.combat: return '⚔️';
      case NodeType.elite: return '💀';
      case NodeType.shrine: return '✨';
      case NodeType.merchant: return '🪙';
      case NodeType.mystery: return '❓';
      case NodeType.boss: return '👑';
    }
  }

  SectorNode copyWith({bool? completed}) {
    return SectorNode(
      id: id,
      depth: depth,
      index: index,
      type: type,
      title: title,
      completed: completed ?? this.completed,
      nextIndices: nextIndices,
    );
  }
}
