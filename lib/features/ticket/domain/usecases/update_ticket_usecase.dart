import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class UpdateTicketStatusUseCase {
  final TicketRepository _repository;
  UpdateTicketStatusUseCase(this._repository);

  Future<TicketEntity> call(String id, String status) {
    return _repository.updateStatus(id, status);
  }
}

class AssignTicketUseCase {
  final TicketRepository _repository;
  AssignTicketUseCase(this._repository);

  Future<TicketEntity> call(String ticketId, String assigneeId) {
    return _repository.assignTicket(ticketId, assigneeId);
  }
}

class AddCommentUseCase {
  final TicketRepository _repository;
  AddCommentUseCase(this._repository);

  Future<void> call(String ticketId, String content) {
    return _repository.addComment(ticketId, content);
  }
}