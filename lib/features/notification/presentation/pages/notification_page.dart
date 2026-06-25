import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifs = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifs = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai semua dibaca: $e')),
      );
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      setState(() {
        final idx = _notifs.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          _notifs[idx] = {..._notifs[idx], 'is_read': true};
        }
      });
    } catch (_) {
      // Diamkan, tidak kritikal
    }
  }

  Future<void> _deleteNotif(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus notifikasi: $e')),
      );
      _loadNotifications();
    }
  }

  /// Menentukan warna & icon berdasarkan judul/isi notifikasi.
  /// Karena tabel `notifications` tidak punya kolom `type` khusus,
  /// kita tebak dari kata kunci pada title.
  Color _typeColor(Map<String, dynamic> n) {
    final title = (n['title'] as String? ?? '').toLowerCase();
    if (title.contains('diproses')) return AppColors.statusInProgress;
    if (title.contains('selesai')) return AppColors.statusResolved;
    if (title.contains('dibuka') || title.contains('baru')) {
      return AppColors.statusOpen;
    }
    if (title.contains('ditutup')) return AppColors.statusClosed;
    return AppColors.primary;
  }

  IconData _typeIcon(Map<String, dynamic> n) {
    final title = (n['title'] as String? ?? '').toLowerCase();
    if (title.contains('diproses')) return Icons.timelapse_rounded;
    if (title.contains('selesai')) return Icons.check_circle_rounded;
    if (title.contains('dibuka')) return Icons.fiber_new_rounded;
    if (title.contains('ditutup')) return Icons.cancel_rounded;
    if (title.contains('komentar')) return Icons.chat_bubble_outline_rounded;
    return Icons.notifications_outlined;
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = _notifs.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tandai Semua Dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_notifs.isEmpty) {
      return ListView(
        // ListView agar RefreshIndicator tetap bisa di-pull
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada notifikasi'),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = _notifs[i];
        final color = _typeColor(n);
        final isRead = n['is_read'] == true;

        return Dismissible(
          key: Key('notif_${n['id']}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            setState(() => _notifs.removeAt(i));
            _deleteNotif(n['id'] as String);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isRead ? theme.cardTheme.color : color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRead ? Colors.transparent : color.withOpacity(0.3),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(n), color: color, size: 22),
              ),
              title: Text(
                n['title'] as String? ?? '',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(n['body'] as String? ?? '',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(n['created_at'] as String?),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              trailing: isRead
                  ? null
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              onTap: () {
                if (!isRead) _markAsRead(n['id'] as String);
                // TODO: Navigasi ke detail tiket terkait via n['ticket_id']
              },
            ),
          ),
        );
      },
    );
  }
}