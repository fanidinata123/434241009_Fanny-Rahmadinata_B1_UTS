import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/ticket_entity.dart';

class TrackingPage extends StatelessWidget {
  final String ticketId;
  final String ticketTitle;

  const TrackingPage({
    super.key,
    required this.ticketId,
    required this.ticketTitle,
  });

  // Simulasi data tracking — nanti dari API ticket_history
  static final _steps = [
    _TrackStep(
      status: TicketStatus.open,
      label: 'Tiket Dibuat',
      desc: 'Laporan kamu sudah diterima sistem',
      time: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      done: true,
    ),
    _TrackStep(
      status: TicketStatus.inProgress,
      label: 'Sedang Diproses',
      desc: 'Helpdesk 1 sedang menangani tiket ini',
      time: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      done: true,
    ),
    _TrackStep(
      status: TicketStatus.resolved,
      label: 'Selesai',
      desc: 'Masalah telah diselesaikan',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      done: false, // belum sampai sini
    ),
    _TrackStep(
      status: TicketStatus.closed,
      label: 'Ditutup',
      desc: 'Tiket ditutup setelah konfirmasi user',
      time: null,
      done: false,
    ),
  ];

  Color _stepColor(TicketStatus s, bool done) {
    if (!done) return const Color(0xFFD3D1C7);
    switch (s) {
      case TicketStatus.open:       return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved:   return AppColors.statusResolved;
      case TicketStatus.closed:     return AppColors.statusClosed;
    }
  }

  // Index step yang sedang aktif (done=true terakhir)
  int get _activeIndex =>
      _steps.lastIndexWhere((s) => s.done);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _activeIndex;
    final currentStep = _steps[active];
    final currentColor = _stepColor(currentStep.status, true);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Tiket')),
      body: ListView(
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
                          ticketId,
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
                  Text(ticketTitle,
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
                              currentStep.label,
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
          ...List.generate(_steps.length, (i) {
            final step = _steps[i];
            final color = _stepColor(step.status, step.done);
            final isLast = i == _steps.length - 1;
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
                              ? Icon(Icons.check_rounded,
                                  color: color, size: 20)
                              : Icon(Icons.radio_button_unchecked,
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.4),
                                  size: 20),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              color: step.done && _steps[i + 1].done
                                  ? color.withOpacity(0.4)
                                  : theme.colorScheme.outline
                                      .withOpacity(0.15),
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
                                  ? theme.colorScheme.onSurface
                                      .withOpacity(0.6)
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
      ),
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