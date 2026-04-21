import '../models/ticket_model.dart';
import '../../domain/entities/ticket_entity.dart';

class TicketRemoteDataSource {
  TicketRemoteDataSource(dynamic dio);

  static final List<TicketModel> _tickets = [
    TicketModel(
      id: 'TKT-001',
      title: 'Komputer tidak bisa menyala',
      description: 'Komputer di ruang lab A-301 tidak bisa menyala sejak pagi. Sudah dicoba menekan tombol power berkali-kali tapi tidak ada respons sama sekali.',
      userId: 'u001',
      assignedTo: 'u004',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      categoryId: 'Hardware',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 18, 8, 0),
      updatedAt: DateTime(2026, 4, 18, 13, 0),
    ),
    TicketModel(
      id: 'TKT-002',
      title: 'Email kampus tidak bisa login',
      description: 'Tidak bisa masuk ke email kampus sejak kemarin. Muncul pesan error "Invalid credentials" padahal password sudah benar dan belum pernah diganti.',
      userId: 'u002',
      assignedTo: null,
      status: TicketStatus.open,
      priority: TicketPriority.medium,
      categoryId: 'Akun & Akses',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 19, 9, 0),
      updatedAt: DateTime(2026, 4, 19, 9, 0),
    ),
    TicketModel(
      id: 'TKT-003',
      title: 'Printer offline tidak bisa print',
      description: 'Printer di ruang TU menampilkan status offline meski sudah dinyalakan dan kabel sudah tersambung ke komputer dengan benar.',
      userId: 'u003',
      assignedTo: 'u004',
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      categoryId: 'Hardware',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 15, 10, 0),
      updatedAt: DateTime(2026, 4, 17, 14, 0),
    ),
    TicketModel(
      id: 'TKT-004',
      title: 'Koneksi WiFi sangat lambat di lantai 2',
      description: 'WiFi di gedung B lantai 2 sangat lambat bahkan sering putus total. Sangat mengganggu kegiatan perkuliahan online dan akses e-learning.',
      userId: 'u001',
      assignedTo: 'u005',
      status: TicketStatus.closed,
      priority: TicketPriority.medium,
      categoryId: 'Jaringan',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 10, 7, 30),
      updatedAt: DateTime(2026, 4, 13, 16, 0),
    ),
    TicketModel(
      id: 'TKT-005',
      title: 'Software SPSS license expired',
      description: 'Aplikasi SPSS di lab statistik error saat dibuka. Muncul pesan "License has expired". Padahal besok ada praktikum yang membutuhkan SPSS.',
      userId: 'u002',
      assignedTo: null,
      status: TicketStatus.open,
      priority: TicketPriority.critical,
      categoryId: 'Software',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 20, 6, 0),
      updatedAt: DateTime(2026, 4, 20, 6, 0),
    ),
    TicketModel(
      id: 'TKT-006',
      title: 'Proyektor ruang kuliah B-201 rusak',
      description: 'Proyektor di ruang B-201 tidak menampilkan gambar. Lampu indikator berkedip merah. Sudah dicoba restart tapi tetap tidak mau menyala normal.',
      userId: 'u003',
      assignedTo: 'u005',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      categoryId: 'Hardware',
      attachmentUrls: const [],
      createdAt: DateTime(2026, 4, 20, 7, 0),
      updatedAt: DateTime(2026, 4, 20, 8, 0),
    ),
  ];

  Future<List<TicketModel>> getTickets({String? status, String? search}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    var result = List<TicketModel>.from(_tickets);

    if (status != null && status.isNotEmpty) {
      final s = TicketStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => TicketStatus.open,
      );
      result = result.where((t) => t.status == s).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q)
      ).toList();
    }

    return result;
  }

  Future<TicketModel> getTicketById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => _tickets.first,
    );
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final newTicket = TicketModel(
      id: 'TKT-00${_tickets.length + 1}',
      title: title,
      description: description,
      userId: 'u001',
      assignedTo: null,
      status: TicketStatus.open,
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == priority,
        orElse: () => TicketPriority.low,
      ),
      categoryId: categoryId,
      attachmentUrls: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tickets.insert(0, newTicket);
    return newTicket;
  }

  Future<TicketModel> updateStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx == -1) throw Exception('Tiket tidak ditemukan');
    final old = _tickets[idx];
    final updated = TicketModel(
      id: old.id,
      title: old.title,
      description: old.description,
      userId: old.userId,
      assignedTo: old.assignedTo,
      status: TicketStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => TicketStatus.open,
      ),
      priority: old.priority,
      categoryId: old.categoryId,
      attachmentUrls: old.attachmentUrls,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  Future<TicketModel> assignTicket(String id, String assigneeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx == -1) throw Exception('Tiket tidak ditemukan');
    final old = _tickets[idx];
    final updated = TicketModel(
      id: old.id,
      title: old.title,
      description: old.description,
      userId: old.userId,
      assignedTo: assigneeId,
      status: TicketStatus.inProgress,
      priority: old.priority,
      categoryId: old.categoryId,
      attachmentUrls: old.attachmentUrls,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  Future<void> addComment(String ticketId, String content) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}