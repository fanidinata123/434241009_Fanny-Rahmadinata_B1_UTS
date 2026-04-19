import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket_entity.dart';

// Events
abstract class TicketEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadTickets extends TicketEvent {
  final String? statusFilter, search;
  LoadTickets({this.statusFilter, this.search});
}
class LoadTicketDetail extends TicketEvent {
  final String id;
  LoadTicketDetail(this.id);
}
class CreateTicket extends TicketEvent {
  final String title, description, priority;
  final String? categoryId;
  final List<MultipartFile>? attachments;
  CreateTicket({
    required this.title,
    required this.description,
    required this.priority,
    this.categoryId,
    this.attachments,
  });
}
class UpdateTicketStatus extends TicketEvent {
  final String id, status;
  UpdateTicketStatus(this.id, this.status);
}
class AssignTicket extends TicketEvent {
  final String id, assigneeId;
  AssignTicket(this.id, this.assigneeId);
}
class AddComment extends TicketEvent {
  final String ticketId, content;
  AddComment(this.ticketId, this.content);
}

// States
abstract class TicketState extends Equatable {
  @override List<Object?> get props => [];
}
class TicketInitial extends TicketState {}
class TicketLoading extends TicketState {}
class TicketListLoaded extends TicketState {
  final List<TicketEntity> tickets;
  TicketListLoaded(this.tickets);
  @override List<Object?> get props => [tickets];
}
class TicketDetailLoaded extends TicketState {
  final TicketEntity ticket;
  TicketDetailLoaded(this.ticket);
  @override List<Object?> get props => [ticket];
}
class TicketCreated extends TicketState {
  final TicketEntity ticket;
  TicketCreated(this.ticket);
}
class TicketUpdated extends TicketState {}
class TicketError extends TicketState {
  final String message;
  TicketError(this.message);
  @override List<Object?> get props => [message];
}

// Bloc
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepositoryImpl _repo;

  TicketBloc(this._repo) : super(TicketInitial()) {
    on<LoadTickets>(_onLoadTickets);
    on<LoadTicketDetail>(_onLoadDetail);
    on<CreateTicket>(_onCreateTicket);
    on<UpdateTicketStatus>(_onUpdateStatus);
    on<AssignTicket>(_onAssign);
    on<AddComment>(_onAddComment);
  }

  Future<void> _onLoadTickets(LoadTickets e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final tickets = await _repo.getTickets(
        status: e.statusFilter,
        search: e.search,
      );
      emit(TicketListLoaded(tickets));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onLoadDetail(LoadTicketDetail e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final ticket = await _repo.getTicketById(e.id);
      emit(TicketDetailLoaded(ticket));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onCreateTicket(CreateTicket e, Emitter<TicketState> emit) async {
    emit(TicketLoading());
    try {
      final ticket = await _repo.createTicket(
        title: e.title,
        description: e.description,
        priority: e.priority,
        categoryId: e.categoryId,
        attachments: e.attachments,
      );
      emit(TicketCreated(ticket));
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onUpdateStatus(UpdateTicketStatus e, Emitter<TicketState> emit) async {
    try {
      await _repo.updateStatus(e.id, e.status);
      emit(TicketUpdated());
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onAssign(AssignTicket e, Emitter<TicketState> emit) async {
    try {
      await _repo.assignTicket(e.id, e.assigneeId);
      emit(TicketUpdated());
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }

  Future<void> _onAddComment(AddComment e, Emitter<TicketState> emit) async {
    try {
      await _repo.addComment(e.ticketId, e.content);
      add(LoadTicketDetail(e.ticketId)); // refresh detail
    } catch (ex) {
      emit(TicketError(ex.toString()));
    }
  }
}