import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  // ── MOCK USERS ──────────────────────────────────────────────
  static final _mockUsers = [
    {'id': 'u001', 'name': 'Fanny Rahmadinata',  'email': 'fanny@demo.com',    'password': '12345678', 'role': 'user'},
    {'id': 'u002', 'name': 'Budi Santoso',        'email': 'budi@demo.com',     'password': '12345678', 'role': 'user'},
    {'id': 'u003', 'name': 'Siti Nurhaliza',      'email': 'siti@demo.com',     'password': '12345678', 'role': 'user'},
    {'id': 'u004', 'name': 'Rizky Pratama',       'email': 'rizky@demo.com',    'password': '12345678', 'role': 'helpdesk'},
    {'id': 'u005', 'name': 'Dewi Anggraini',      'email': 'dewi@demo.com',     'password': '12345678', 'role': 'helpdesk'},
    {'id': 'u006', 'name': 'Ahmad Fauzi',         'email': 'ahmad@demo.com',    'password': '12345678', 'role': 'admin'},
  ];

  // Daftar user yang sudah register (bisa bertambah)
  static final List<Map<String, dynamic>> _registeredUsers =
      List.from(_mockUsers);

  AuthRemoteDataSource(dynamic dio); // dio tetap ada tapi tidak dipakai saat mock

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _registeredUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      throw Exception('Email atau password salah');
    }

    const mockToken = 'mock-jwt-token-helpdesk-2026';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', mockToken);
    await prefs.setString('user_id',   user['id']!);
    await prefs.setString('user_name', user['name']!);
    await prefs.setString('user_email',user['email']!);
    await prefs.setString('user_role', user['role']!);

    return {'token': mockToken, 'user': user};
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final exists = _registeredUsers.any((u) => u['email'] == email);
    if (exists) throw Exception('Email sudah terdaftar');

    final newUser = {
      'id':       'u${DateTime.now().millisecondsSinceEpoch}',
      'name':     name,
      'email':    email,
      'password': password,
      'role':     'user',
    };
    _registeredUsers.add(newUser);
    return UserModel.fromJson(newUser);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final exists = _registeredUsers.any((u) => u['email'] == email);
    if (!exists) throw Exception('Email tidak ditemukan');
    // Mock: pura-pura kirim email
  }

  Future<UserModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    return UserModel.fromJson({
      'id':    prefs.getString('user_id')    ?? 'u001',
      'name':  prefs.getString('user_name')  ?? 'User Demo',
      'email': prefs.getString('user_email') ?? 'user@demo.com',
      'role':  prefs.getString('user_role')  ?? 'user',
    });
  }
}