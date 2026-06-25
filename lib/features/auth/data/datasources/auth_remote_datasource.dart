import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) throw Exception('Login gagal');

    // Ambil data user dari tabel users
    final userData = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .single();

    // Cek status aktif akun. Jika sudah dinonaktifkan oleh admin,
    // tolak login dan langsung sign-out dari sesi Supabase Auth
    // yang baru saja terbentuk (supaya tidak ada sesi "menggantung").
    final isActive = userData['is_active'] as bool? ?? true;
    if (!isActive) {
      await _supabase.auth.signOut();
      throw Exception(
        'Akun Anda telah dinonaktifkan oleh admin. Hubungi administrator untuk informasi lebih lanjut.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', response.session?.accessToken ?? '');
    await prefs.setString('user_id', userData['id']);
    await prefs.setString('user_name', userData['name']);
    await prefs.setString('user_email', userData['email']);
    await prefs.setString('user_role', userData['role']);

    return {'token': response.session?.accessToken, 'user': userData};
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'full_name': name,
      },
    );

    if (response.user == null) throw Exception('Registrasi gagal');

    // Jika trigger belum sempat jalan, insert manual sebagai fallback
    try {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'password_hash': '-',
        'role': 'user',
        'is_active': true,
      });
    } catch (_) {
      // Abaikan jika sudah ada (trigger sudah insert duluan)
    }

    return UserModel.fromJson({
      'id': response.user!.id,
      'name': name,
      'email': email,
      'role': 'user',
    });
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserModel.fromJson({
      'id':    prefs.getString('user_id')    ?? '',
      'name':  prefs.getString('user_name')  ?? '',
      'email': prefs.getString('user_email') ?? '',
      'role':  prefs.getString('user_role')  ?? 'user',
    });
  }
}