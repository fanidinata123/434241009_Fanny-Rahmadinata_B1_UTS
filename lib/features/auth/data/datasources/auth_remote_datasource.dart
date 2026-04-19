import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    final token = res.data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return res.data;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await dio.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(res.data['user']);
  }

  Future<void> logout() async {
    await dio.post(ApiConstants.logout);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> resetPassword(String email) async {
    await dio.post(ApiConstants.resetPassword, data: {'email': email});
  }

  Future<UserModel> getProfile() async {
    final res = await dio.get(ApiConstants.profile);
    return UserModel.fromJson(res.data);
  }
}