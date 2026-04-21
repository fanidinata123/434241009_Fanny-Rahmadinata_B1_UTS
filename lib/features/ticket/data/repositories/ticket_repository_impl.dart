import '../datasources/ticket_remote_datasource.dart';
import '../../domain/entities/ticket_entity.dart';

class TicketRepositoryImpl {
  final TicketRemoteDataSource _remote;
  TicketRepositoryImpl(this._remote);

  Future<List<TicketEntity>> getTickets({String? status, String? search}) async {
    final result = await _remote.getTickets(status: status, search: search);
    return result.cast<TicketEntity>();
  }

  Future<TicketEntity> getTicketById(String id) =>
      _remote.getTicketById(id);

  Future<TicketEntity> createTicket({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
    List<dynamic>? attachments,
  }) =>
      _remote.createTicket(
        title: title,
        description: description,
        priority: priority,
        categoryId: categoryId,
      );

  Future<TicketEntity> updateStatus(String id, String status) =>
      _remote.updateStatus(id, status);

  Future<TicketEntity> assignTicket(String id, String assigneeId) =>
      _remote.assignTicket(id, assigneeId);

  Future<void> addComment(String ticketId, String content) =>
      _remote.addComment(ticketId, content);
}