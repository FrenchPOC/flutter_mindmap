import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Force-directed graph layout algorithm
///
/// Uses physics simulation with repulsion between nodes and attraction along edges
/// to create an organic, balanced layout
class ForceDirectedLayout {
  /// Strength of repulsion between nodes
  static const double repulsionStrength = 5000;

  /// Strength of attraction along edges
  static const double attractionStrength = 0.1;

  /// Damping factor to stabilize the simulation
  static const double damping = 0.8;

  /// Minimum distance maintained between nodes
  static const double minDistance = 150;

  /// Calculates one iteration of the force-directed layout
  ///
  /// Updates node positions and velocities based on forces
  static void calculate(
    List<MindMapNode> nodes,
    List<MindMapEdge> edges,
    Size size,
  ) {
    // Initialize random positions if needed
    final random = Random();
    for (var node in nodes) {
      if (node.position == Offset.zero) {
        node.position = Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      }
    }

    // Apply forces
    for (var node in nodes) {
      var force = Offset.zero;

      // Repulsion between all nodes
      for (var other in nodes) {
        if (node.id != other.id) {
          final delta = node.position - other.position;
          final distance = max(delta.distance, 1.0);
          final repulsion = (repulsionStrength / (distance * distance));
          force += Offset(
            delta.dx / distance * repulsion,
            delta.dy / distance * repulsion,
          );
        }
      }

      // Attraction along edges
      for (var edge in edges) {
        if (edge.fromId == node.id) {
          final other = nodes.firstWhere((n) => n.id == edge.toId);
          final delta = other.position - node.position;
          final distance = max(delta.distance, 1.0);
          final attraction = (distance - minDistance) * attractionStrength;
          force += Offset(
            delta.dx / distance * attraction,
            delta.dy / distance * attraction,
          );
        } else if (edge.toId == node.id) {
          final other = nodes.firstWhere((n) => n.id == edge.fromId);
          final delta = other.position - node.position;
          final distance = max(delta.distance, 1.0);
          final attraction = (distance - minDistance) * attractionStrength;
          force += Offset(
            delta.dx / distance * attraction,
            delta.dy / distance * attraction,
          );
        }
      }

      // Update velocity and position
      node.velocity = (node.velocity + force) * damping;
      node.position += node.velocity;
    }
  }
}
