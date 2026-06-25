import '../../domain/entities/ticket_entity.dart';

class TicketModel extends TicketEntity {
  TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.userId,
    super.assignedTo,
    required super.status,
    required super.priority,
    super.categoryId,
    super.attachmentUrls,
    required super.createdAt,
    required super.updatedAt,
  });

  // Mapping nilai enum di database (snake_case) -> enum Dart (camelCase)
  static TicketStatus _statusFromString(String? value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  static TicketPriority _priorityFromString(String? value) {
    switch (value) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      case 'critical':
        return TicketPriority.critical;
      default:
        return TicketPriority.low;
    }
  }

  factory TicketModel.fromJson(Map<String, dynamic> j) {
    return TicketModel(
      id: j['id'],
      title: j['title'],
      description: j['description'],
      userId: j['user_id'],
      assignedTo: j['assigned_to'],
      status: _statusFromString(j['status'] as String?),
      priority: _priorityFromString(j['priority'] as String?),
      categoryId: j['category_id'],
      attachmentUrls: List<String>.from(j['attachments'] ?? []),
      createdAt: DateTime.parse(j['created_at']),
      updatedAt: DateTime.parse(j['updated_at']),
    );
  }
}