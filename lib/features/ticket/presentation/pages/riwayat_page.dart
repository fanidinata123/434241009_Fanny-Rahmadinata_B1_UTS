import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<_RiwayatItem> _riwayatList = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Ambil riwayat tiket beserta judul tiket terkait dan nama user yang melakukan perubahan.
      final data = await _supabase
          .from('ticket_history')
          .select('''
            id,
            ticket_id,
            field_changed,
            old_value,
            new_value,
            changed_at,
            tickets:ticket_id ( title, status ),
            users:changed_by ( name )
          ''')
          .order('changed_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data as List);

      setState(() {
        _riwayatList = rows.map((row) {
          final ticket = row['tickets'] as Map<String, dynamic>?;
          final user = row['users'] as Map<String, dynamic>?;

          final fieldChanged = row['field_changed'] as String? ?? '';
          final newValue = row['new_value'] as String?;
          final ticketTitle = ticket?['title'] as String? ?? '(Tiket tidak ditemukan)';
          final actorName = user?['name'] as String? ?? 'Sistem';

          String action;
          TicketStatus newStatus;

          if (fieldChanged == 'status') {
            newStatus = _statusFromDb(newValue);
            action = 'Status berubah ke ${_statusLabel(newStatus)}';
          } else if (fieldChanged == 'assigned_to') {
            newStatus = _statusFromDb(ticket?['status'] as String?);
            action = newValue == null
                ? 'Tiket di-unassign'
                : 'Tiket di-assign ke helpdesk';
          } else {
            newStatus = _statusFromDb(ticket?['status'] as String?);
            action = 'Perubahan pada field "$fieldChanged"';
          }

          return _RiwayatItem(
            ticketId: row['ticket_id'] as String,
            title: ticketTitle,
            action: action,
            actor: actorName,
            time: DateTime.parse(row['changed_at'] as String),
            newStatus: newStatus,
          );
        }).toList();

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  TicketStatus _statusFromDb(String? value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:       return 'Dibuka';
      case TicketStatus.inProgress: return 'Diproses';
      case TicketStatus.resolved:   return 'Selesai';
      case TicketStatus.closed:     return 'Ditutup';
    }
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
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_riwayatList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada riwayat aktivitas'),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabCtrl,
      children: [
        RefreshIndicator(onRefresh: _loadHistory, child: _buildTimeline(theme)),
        RefreshIndicator(onRefresh: _loadHistory, child: _buildPerTicket(theme)),
      ],
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
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.ticketId.substring(0, 8),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
              entry.value.first.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              entry.key.substring(0, 8),
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