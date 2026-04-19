import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class GetTicketsUseCase {
  final TicketRepository _repository;
  GetTicketsUseCase(this._repository);

  Future<List<TicketEntity>> call({String? status, String? search}) {
    return _repository.getTickets(status: status, search: search);
  }
}

class GetTicketDetailUseCase {
  final TicketRepository _repository;
  GetTicketDetailUseCase(this._repository);

  Future<TicketEntity> call(String id) {
    return _repository.getTicketById(id);
  }
}