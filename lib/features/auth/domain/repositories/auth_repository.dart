import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<UserEntity> getProfile();
}