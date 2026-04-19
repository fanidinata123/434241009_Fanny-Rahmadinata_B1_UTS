// ticket_entity.dart
enum TicketStatus { open, inProgress, resolved, closed }
enum TicketPriority { low, medium, high, critical }

class TicketEntity {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String? assignedTo;
  final TicketStatus status;
  final TicketPriority priority;
  final String? categoryId;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    this.assignedTo,
    required this.status,
    required this.priority,
    this.categoryId,
    this.attachmentUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case TicketStatus.open: return 'Dibuka';
      case TicketStatus.inProgress: return 'Diproses';
      case TicketStatus.resolved: return 'Selesai';
      case TicketStatus.closed: return 'Ditutup';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low: return 'Rendah';
      case TicketPriority.medium: return 'Sedang';
      case TicketPriority.high: return 'Tinggi';
      case TicketPriority.critical: return 'Kritis';
    }
  }
}

// ---- ticket_model.dart ----
class TicketModel extends TicketEntity {
  const TicketModel({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'user_id': userId,
        'assigned_to': assignedTo,
        'status': status.name,
        'priority': priority.name,
        'category_id': categoryId,
        'attachments': attachmentUrls,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}