import 'dart:convert';

/// Type of entity represented in the sync queue.
enum EntityType { project, task }

/// CRUD operation to be performed remotely.
enum OperationType { create, update, delete }

/// Represents a single offline change that must be synced to Supabase.
class PendingChange {
  final String id;
  final EntityType entityType;
  final OperationType operation;
  final String entityId;
  final Map<String, dynamic> payloadJson;
  final DateTime createdAt;

  PendingChange({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.entityId,
    required this.payloadJson,
    required this.createdAt,
  });

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'operation': operation.name,
      'payload_json': jsonEncode(payloadJson),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingChange.fromRow(Map<String, dynamic> row) {
    return PendingChange(
      id: row['id'] as String,
      entityType: EntityType.values.firstWhere(
        (e) => e.name == row['entity_type'],
        orElse: () => EntityType.task,
      ),
      operation: OperationType.values.firstWhere(
        (e) => e.name == row['operation'],
        orElse: () => OperationType.update,
      ),
      entityId: row['entity_id'] as String,
      payloadJson:
          jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
