import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Data dummy - nanti diganti dari API
  static final _notifs = [
    _NotifData(
      title: 'Tiket #001 Diperbarui',
      body: 'Status tiket Anda berubah menjadi "Diproses".',
      time: '10 menit lalu',
      isRead: false,
      type: 'in_progress',
    ),
    _NotifData(
      title: 'Tiket #002 Selesai',
      body: 'Tiket Anda telah diselesaikan oleh Helpdesk 1.',
      time: '1 jam lalu',
      isRead: false,
      type: 'resolved',
    ),
    _NotifData(
      title: 'Tiket #003 Dibuka',
      body: 'Tiket baru Anda berhasil dikirim dan sedang menunggu.',
      time: '3 jam lalu',
      isRead: true,
      type: 'open',
    ),
    _NotifData(
      title: 'Komentar Baru',
      body: 'Helpdesk membalas komentar di Tiket #001.',
      time: 'Kemarin',
      isRead: true,
      type: 'comment',
    ),
  ];

  Color _typeColor(String type) {
    switch (type) {
      case 'in_progress': return AppColors.statusInProgress;
      case 'resolved': return AppColors.statusResolved;
      case 'open': return AppColors.statusOpen;
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'in_progress': return Icons.timelapse_rounded;
      case 'resolved': return Icons.check_circle_rounded;
      case 'open': return Icons.fiber_new_rounded;
      default: return Icons.chat_bubble_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = _notifs.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {},
              child: const Text('Tandai Semua Dibaca'),
            ),
        ],
      ),
      body: _notifs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada notifikasi'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = _notifs[i];
                final color = _typeColor(n.type);
                return Dismissible(
                  key: Key('notif_$i'),
                  direction: DismissDirection.endToStart,
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
                      color: n.isRead
                          ? theme.cardTheme.color
                          : color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: n.isRead
                            ? Colors.transparent
                            : color.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon(n.type), color: color, size: 22),
                      ),
                      title: Text(
                        n.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(n.body, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            n.time,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      trailing: n.isRead
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
                        // Navigasi ke detail tiket terkait
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NotifData {
  final String title, body, time, type;
  final bool isRead;
  const _NotifData({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.isRead,
  });
}