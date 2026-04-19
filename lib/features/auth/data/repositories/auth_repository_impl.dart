import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);

  Future<UserEntity> login(String email, String password) async {
    final data = await _remote.login(email, password);
    return UserEntity(
      id: data['user']['id'],
      name: data['user']['name'],
      email: data['user']['email'],
      role: UserRole.values.firstWhere(
        (r) => r.name == data['user']['role'],
        orElse: () => UserRole.user,
      ),
      avatarUrl: data['user']['avatar_url'],
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _remote.register(name: name, email: email, password: password);

  Future<void> logout() => _remote.logout();

  Future<void> resetPassword(String email) => _remote.resetPassword(email);

  Future<UserEntity> getProfile() => _remote.getProfile();
}