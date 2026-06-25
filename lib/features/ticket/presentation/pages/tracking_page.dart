import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/ticket_entity.dart';

class TrackingPage extends StatefulWidget {
  final String ticketId;
  final String ticketTitle;

  const TrackingPage({
    super.key,
    required this.ticketId,
    required this.ticketTitle,
  });

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  TicketStatus _currentStatus = TicketStatus.open;
  String _title = '';

  // Waktu untuk masing-masing tahap, null jika belum terjadi
  DateTime? _createdAt;
  DateTime? _inProgressAt;
  DateTime? _resolvedAt;
  DateTime? _closedAt;

  static const _statusOrder = [
    TicketStatus.open,
    TicketStatus.inProgress,
    TicketStatus.resolved,
    TicketStatus.closed,
  ];

  @override
  void initState() {
    super.initState();
    _title = widget.ticketTitle;
    _loadTracking();
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

  Future<void> _loadTracking() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Ambil data tiket saat ini (status + created_at)
      final ticket = await _supabase
          .from('tickets')
          .select('title, status, created_at')
          .eq('id', widget.ticketId)
          .single();

      _title = ticket['title'] as String? ?? widget.ticketTitle;
      _currentStatus = _statusFromDb(ticket['status'] as String?);
      _createdAt = DateTime.tryParse(ticket['created_at'] as String? ?? '');

      // 2. Ambil riwayat perubahan status dari ticket_history
      final history = await _supabase
          .from('ticket_history')
          .select('new_value, changed_at')
          .eq('ticket_id', widget.ticketId)
          .eq('field_changed', 'status')
          .order('changed_at', ascending: true);

      for (final row in (history as List)) {
        final status = _statusFromDb(row['new_value'] as String?);
        final time = DateTime.tryParse(row['changed_at'] as String? ?? '');
        switch (status) {
          case TicketStatus.inProgress:
            _inProgressAt = time;
            break;
          case TicketStatus.resolved:
            _resolvedAt = time;
            break;
          case TicketStatus.closed:
            _closedAt = time;
            break;
          case TicketStatus.open:
            break;
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _stepColor(TicketStatus s, bool done) {
    if (!done) return const Color(0xFFD3D1C7);
    switch (s) {
      case TicketStatus.open: return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved: return AppColors.statusResolved;
      case TicketStatus.closed: return AppColors.statusClosed;
    }
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open: return 'Dibuka';
      case TicketStatus.inProgress: return 'Sedang Diproses';
      case TicketStatus.resolved: return 'Selesai';
      case TicketStatus.closed: return 'Ditutup';
    }
  }

  List<_TrackStep> get _steps {
    // done = tahap ini sudah terlewati / tercapai berdasarkan urutan status
    final currentIndex = _statusOrder.indexOf(_currentStatus);

    return [
      _TrackStep(
        status: TicketStatus.open,
        label: 'Tiket Dibuat',
        desc: 'Laporan kamu sudah diterima sistem',
        time: _createdAt,
        done: currentIndex >= 0,
      ),
      _TrackStep(
        status: TicketStatus.inProgress,
        label: 'Sedang Diproses',
        desc: 'Helpdesk sedang menangani tiket ini',
        time: _inProgressAt,
        done: currentIndex >= 1,
      ),
      _TrackStep(
        status: TicketStatus.resolved,
        label: 'Selesai',
        desc: 'Masalah telah diselesaikan',
        time: _resolvedAt,
        done: currentIndex >= 2,
      ),
      _TrackStep(
        status: TicketStatus.closed,
        label: 'Ditutup',
        desc: 'Tiket ditutup setelah konfirmasi user',
        time: _closedAt,
        done: currentIndex >= 3,
      ),
    ];
  }

  // Index step yang sedang aktif (done=true terakhir)
  int get _activeIndex => _steps.lastIndexWhere((s) => s.done);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Tiket')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadTracking,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTracking,
                  child: _buildContent(theme),
                ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final steps = _steps;
    final active = _activeIndex;
    final currentStep = steps[active < 0 ? 0 : active];
    final currentColor = _stepColor(currentStep.status, true);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header tiket
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.ticketId.substring(0, 8),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Status saat ini
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: currentColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: currentColor),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(_currentStatus),
                            style: TextStyle(
                              color: currentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text('Progres Penanganan',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Stepper tracking
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final color = _stepColor(step.status, step.done);
          final isLast = i == steps.length - 1;
          final isActive = i == active;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot + garis
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: step.done
                              ? color.withOpacity(0.15)
                              : theme.colorScheme.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: step.done
                            ? Icon(Icons.check_rounded, color: color, size: 20)
                            : Icon(Icons.radio_button_unchecked,
                                color: theme.colorScheme.outline
                                    .withOpacity(0.4),
                                size: 20),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: step.done && steps[i + 1].done
                                ? color.withOpacity(0.4)
                                : theme.colorScheme.outline.withOpacity(0.15),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Teks
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: step.done
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: step.done
                                ? theme.colorScheme.onSurface.withOpacity(0.6)
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                          ),
                        ),
                        if (step.time != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35)),
                              const SizedBox(width: 3),
                              Text(
                                DateFormatter.formatFull(step.time!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TrackStep {
  final TicketStatus status;
  final String label;
  final String desc;
  final DateTime? time;
  final bool done;

  const _TrackStep({
    required this.status,
    required this.label,
    required this.desc,
    required this.time,
    required this.done,
  });
}