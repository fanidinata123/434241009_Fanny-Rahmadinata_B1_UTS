import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class CreateTicketUseCase {
  final TicketRepository _repository;
  CreateTicketUseCase(this._repository);

  Future<TicketEntity> call({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
    List<dynamic>? attachments,
  }) {
    return _repository.createTicket(
      title: title,
      description: description,
      priority: priority,
      categoryId: categoryId,
      attachments: attachments,
    );
  }
}