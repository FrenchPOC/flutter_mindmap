/// Represents a connection between two nodes in the mind map
class MindMapEdge {
  /// ID of the source node
  final String fromId;

  /// ID of the target node
  final String toId;

  const MindMapEdge({required this.fromId, required this.toId});

  /// Creates an edge from JSON data
  factory MindMapEdge.fromJson(Map<String, dynamic> json) {
    return MindMapEdge(
      fromId: json['from']?.toString() ?? '',
      toId: json['to']?.toString() ?? '',
    );
  }

  /// Converts the edge to JSON format
  Map<String, dynamic> toJson() {
    return {'from': fromId, 'to': toId};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MindMapEdge && other.fromId == fromId && other.toId == toId;
  }

  @override
  int get hashCode => fromId.hashCode ^ toId.hashCode;
}
