import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/ticket_entity.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Data dummy — nanti dari API
  final _riwayatList = [
    _RiwayatItem(
      ticketId: 'TKT-001',
      title: 'Komputer tidak bisa menyala',
      action: 'Status berubah ke Selesai',
      actor: 'Helpdesk 1',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      newStatus: TicketStatus.resolved,
    ),
    _RiwayatItem(
      ticketId: 'TKT-001',
      title: 'Komputer tidak bisa menyala',
      action: 'Tiket di-assign ke Helpdesk 1',
      actor: 'Admin',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      newStatus: TicketStatus.inProgress,
    ),
    _RiwayatItem(
      ticketId: 'TKT-002',
      title: 'Email tidak bisa login',
      action: 'Tiket dibuat oleh User Demo',
      actor: 'User Demo',
      time: DateTime.now().subtract(const Duration(days: 1)),
      newStatus: TicketStatus.open,
    ),
    _RiwayatItem(
      ticketId: 'TKT-003',
      title: 'Printer offline',
      action: 'Status berubah ke Ditutup',
      actor: 'Admin',
      time: DateTime.now().subtract(const Duration(days: 2)),
      newStatus: TicketStatus.closed,
    ),
    _RiwayatItem(
      ticketId: 'TKT-003',
      title: 'Printer offline',
      action: 'Komentar ditambahkan',
      actor: 'Helpdesk 2',
      time: DateTime.now().subtract(const Duration(days: 3)),
      newStatus: TicketStatus.inProgress,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:       return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved:   return AppColors.statusResolved;
      case TicketStatus.closed:     return AppColors.statusClosed;
    }
  }

  IconData _statusIcon(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:       return Icons.fiber_new_rounded;
      case TicketStatus.inProgress: return Icons.timelapse_rounded;
      case TicketStatus.resolved:   return Icons.check_circle_rounded;
      case TicketStatus.closed:     return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tiket'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Semua Aktivitas'),
            Tab(text: 'Per Tiket'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Timeline semua aktivitas
          _buildTimeline(theme),
          // Tab 2: Dikelompokkan per tiket
          _buildPerTicket(theme),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatList.length,
      itemBuilder: (_, i) {
        final item = _riwayatList[i];
        final color = _statusColor(item.newStatus);
        final isLast = i == _riwayatList.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(item.newStatus),
                          color: color, size: 18),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Konten
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.ticketId,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormatter.format(item.time),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.action,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 3),
                          Text(
                            item.actor,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerTicket(ThemeData theme) {
    // Kelompokkan per ticketId
    final grouped = <String, List<_RiwayatItem>>{};
    for (final item in _riwayatList) {
      grouped.putIfAbsent(item.ticketId, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              entry.key,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              entry.value.first.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Text(
              '${entry.value.length} aktivitas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: entry.value
                .map(
                  (item) => ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Icon(
                      _statusIcon(item.newStatus),
                      color: _statusColor(item.newStatus),
                      size: 20,
                    ),
                    title: Text(item.action,
                        style: theme.textTheme.bodySmall),
                    subtitle: Text(
                      '${item.actor} • ${DateFormatter.format(item.time)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _RiwayatItem {
  final String ticketId;
  final String title;
  final String action;
  final String actor;
  final DateTime time;
  final TicketStatus newStatus;

  const _RiwayatItem({
    required this.ticketId,
    required this.title,
    required this.action,
    required this.actor,
    required this.time,
    required this.newStatus,
  });
}