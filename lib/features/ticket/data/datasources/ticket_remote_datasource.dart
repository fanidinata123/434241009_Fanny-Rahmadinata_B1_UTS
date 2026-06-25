import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_model.dart';
import '../../domain/entities/ticket_entity.dart';

class TicketRemoteDataSource {
  final _supabase = Supabase.instance.client;

  // Konversi status dari Dart enum-name (camelCase) -> nilai enum DB (snake_case)
  String _statusToDb(String status) {
    switch (status) {
      case 'inProgress':
        return 'in_progress';
      default:
        return status; // open, resolved, closed sudah sama
    }
  }

  Future<List<TicketModel>> getTickets({
    String? status,
    String? search,
    String? assignedTo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'user';
    final userId = prefs.getString('user_id') ?? '';

    var query = _supabase.from('tickets').select();

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', _statusToDb(status));
    }

    // Sesuai SRS: helpdesk hanya boleh melihat tiket yang
    // ditugaskan (assigned) ke dirinya sendiri. Admin tetap
    // melihat semua tiket, dan user (RLS) otomatis hanya melihat
    // tiketnya sendiri.
    if (role == 'helpdesk') {
      query = query.eq('assigned_to', userId);
    } else if (role == 'admin' && assignedTo != null && assignedTo.isNotEmpty) {
      // Admin bisa memfilter tiket berdasarkan helpdesk tertentu
      // yang ditugaskan (FR-007.3).
      query = query.eq('assigned_to', assignedTo);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  /// Mengambil daftar helpdesk aktif, digunakan oleh admin untuk
  /// memfilter tiket berdasarkan helpdesk yang ditugaskan.
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    final data = await _supabase
        .from('users')
        .select('id, name')
        .eq('role', 'helpdesk')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<TicketModel> getTicketById(String id) async {
    final data = await _supabase
        .from('tickets')
        .select()
        .eq('id', id)
        .single();
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    final data = await _supabase.from('tickets').insert({
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'open',
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
    }).select().single();

    return TicketModel.fromJson(data);
  }

  Future<TicketModel> updateStatus(String id, String status) async {
    final data = await _supabase
        .from('tickets')
        .update({
          'status': _statusToDb(status),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> assignTicket(String id, String assigneeId) async {
    final data = await _supabase
        .from('tickets')
        .update({
          'assigned_to': assigneeId,
          'status': 'in_progress',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return TicketModel.fromJson(data);
  }

  Future<void> addComment(String ticketId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    await _supabase.from('comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'content': content,
    });
  }

  Future<void> deleteTicket(String id) async {
    await _supabase.from('tickets').delete().eq('id', id);
  }

  /// Mengambil statistik jumlah tiket berdasarkan status.
  ///
  /// - Untuk role `user`: hanya menghitung tiket milik user sendiri
  ///   (dibatasi oleh RLS policy "Users can view own tickets").
  /// - Untuk role `helpdesk`: hanya menghitung tiket yang DI-ASSIGN
  ///   ke dirinya sendiri (sesuai SRS FR-006: helpdesk hanya
  ///   menangani tiket yang ditugaskan).
  /// - Untuk role `admin`: menghitung SEMUA tiket (diizinkan oleh
  ///   RLS policy "Helpdesk and admin can view all tickets").
  Future<Map<String, int>> getTicketStats() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'user';
    final userId = prefs.getString('user_id') ?? '';

    var query = _supabase.from('tickets').select('status');

    if (role == 'helpdesk') {
      query = query.eq('assigned_to', userId);
    }

    final data = await query;
    final rows = data as List;

    int total = rows.length;
    int open = 0, inProgress = 0, resolved = 0, closed = 0;

    for (final row in rows) {
      switch (row['status']) {
        case 'open':
          open++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'closed':
          closed++;
          break;
      }
    }

    return {
      'total': total,
      'open': open,
      'in_progress': inProgress,
      'resolved': resolved,
      'closed': closed,
    };
  }
}