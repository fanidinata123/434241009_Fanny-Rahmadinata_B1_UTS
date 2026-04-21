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

  TicketEntity({
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
      case TicketStatus.open:       return 'Dibuka';
      case TicketStatus.inProgress: return 'Diproses';
      case TicketStatus.resolved:   return 'Selesai';
      case TicketStatus.closed:     return 'Ditutup';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low:      return 'Rendah';
      case TicketPriority.medium:   return 'Sedang';
      case TicketPriority.high:     return 'Tinggi';
      case TicketPriority.critical: return 'Kritis';
    }
  }
}