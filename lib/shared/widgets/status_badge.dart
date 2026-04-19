import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/ticket/domain/entities/ticket_entity.dart';

class StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const StatusBadge({super.key, required this.status});

  String get _label {
    switch (status) {
      case TicketStatus.open:       return 'Dibuka';
      case TicketStatus.inProgress: return 'Diproses';
      case TicketStatus.resolved:   return 'Selesai';
      case TicketStatus.closed:     return 'Ditutup';
    }
  }

  Color get _color {
    switch (status) {
      case TicketStatus.open:       return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved:   return AppColors.statusResolved;
      case TicketStatus.closed:     return AppColors.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) => _Badge(label: _label, color: _color);
}

class PriorityBadge extends StatelessWidget {
  final TicketPriority priority;

  const PriorityBadge({super.key, required this.priority});

  String get _label {
    switch (priority) {
      case TicketPriority.low:      return 'Rendah';
      case TicketPriority.medium:   return 'Sedang';
      case TicketPriority.high:     return 'Tinggi';
      case TicketPriority.critical: return 'Kritis';
    }
  }

  Color get _color {
    switch (priority) {
      case TicketPriority.low:      return AppColors.priorityLow;
      case TicketPriority.medium:   return AppColors.priorityMedium;
      case TicketPriority.high:     return AppColors.priorityHigh;
      case TicketPriority.critical: return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) => _Badge(label: _label, color: _color);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}