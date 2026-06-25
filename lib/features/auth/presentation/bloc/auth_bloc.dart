import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}
class RegisterRequested extends AuthEvent {
  final String name, email, password;
  RegisterRequested(this.name, this.email, this.password);
  @override List<Object?> get props => [name, email, password];
}
class LogoutRequested extends AuthEvent {}
class ResetPasswordRequested extends AuthEvent {
  final String email;
  ResetPasswordRequested(this.email);
}
class GetProfileRequested extends AuthEvent {}
class UpdatePasswordRequested extends AuthEvent {
  final String newPassword;
  UpdatePasswordRequested(this.newPassword);
  @override List<Object?> get props => [newPassword];
}

// States
abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class AuthPasswordResetSent extends AuthState {}
class AuthPasswordUpdated extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ResetPasswordRequested>(_onResetPassword);
    on<GetProfileRequested>(_onGetProfile);
    on<UpdatePasswordRequested>(_onUpdatePassword);
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.login(e.email, e.password);
      emit(AuthAuthenticated(user));
    } catch (ex) {
      emit(AuthError(ex.toString()));
    }
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.register(name: e.name, email: e.email, password: e.password);
      emit(AuthUnauthenticated());
    } catch (ex) {
      emit(AuthError(ex.toString()));
    }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onResetPassword(ResetPasswordRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.resetPassword(e.email);
      emit(AuthPasswordResetSent());
    } catch (ex) {
      emit(AuthError(ex.toString()));
    }
  }

  Future<void> _onGetProfile(GetProfileRequested e, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.getProfile();
      emit(AuthAuthenticated(user));
    } catch (ex) {
      // Diam saja jika gagal refresh profil — state lama tetap dipakai
    }
  }

  Future<void> _onUpdatePassword(UpdatePasswordRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.updatePassword(e.newPassword);
      // Pertahankan state authenticated setelah update password
      final user = await _repo.getProfile();
      emit(AuthAuthenticated(user));
      emit(AuthPasswordUpdated());
    } catch (ex) {
      emit(AuthError(ex.toString()));
    }
  }
}