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

  factory TicketModel.fromJson(Map<String, dynamic> j) {
    return TicketModel(
      id: j['id'],
      title: j['title'],
      description: j['description'],
      userId: j['user_id'],
      assignedTo: j['assigned_to'],
      status: TicketStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == j['priority'],
        orElse: () => TicketPriority.low,
      ),
      categoryId: j['category_id'],
      attachmentUrls: List<String>.from(j['attachments'] ?? []),
      createdAt: DateTime.parse(j['created_at']),
      updatedAt: DateTime.parse(j['updated_at']),
    );
  }
}