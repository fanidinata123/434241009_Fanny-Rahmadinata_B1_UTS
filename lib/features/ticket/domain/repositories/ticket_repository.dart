import '../entities/ticket_entity.dart';

abstract class TicketRepository {
  Future<List<TicketEntity>> getTickets({String? status, String? search});
  Future<TicketEntity> getTicketById(String id);
  Future<TicketEntity> createTicket({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
    List<dynamic>? attachments,
  });
  Future<TicketEntity> updateStatus(String id, String status);
  Future<TicketEntity> assignTicket(String id, String assigneeId);
  Future<void> addComment(String ticketId, String content);
}