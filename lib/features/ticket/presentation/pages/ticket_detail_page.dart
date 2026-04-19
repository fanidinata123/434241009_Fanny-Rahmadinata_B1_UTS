import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ticket_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'tracking_page.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTicketDetail(widget.ticketId));
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<TicketBloc>().add(AddComment(widget.ticketId, text));
    _commentCtrl.clear();
  }

  void _showStatusDialog(TicketEntity ticket) {
    final options = TicketStatus.values;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Status Tiket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((s) {
            return RadioListTile<TicketStatus>(
              title: Text(ticket.statusLabel),
              value: s,
              groupValue: ticket.status,
              onChanged: (val) {
                if (val != null) {
                  context.read<TicketBloc>().add(
                        UpdateTicketStatus(widget.ticketId, val.name),
                      );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open: return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved: return AppColors.statusResolved;
      case TicketStatus.closed: return AppColors.statusClosed;
    }
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.low: return AppColors.priorityLow;
      case TicketPriority.medium: return AppColors.priorityMedium;
      case TicketPriority.high: return AppColors.priorityHigh;
      case TicketPriority.critical: return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isHelpdesk = authState is AuthAuthenticated && authState.user.isHelpdesk;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          // Tombol tracking untuk semua user
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            tooltip: 'Tracking',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackingPage(
                  ticketId: widget.ticketId,
                  ticketTitle: context.read<TicketBloc>().state
                      is TicketDetailLoaded
                      ? (context.read<TicketBloc>().state as TicketDetailLoaded)
                          .ticket.title
                      : 'Tiket',
                ),
              ),
            ),
          ),
          if (isHelpdesk)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Status',
              onPressed: () {
                final state = context.read<TicketBloc>().state;
                if (state is TicketDetailLoaded) _showStatusDialog(state.ticket);
              },
            ),
        ],
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (ctx, state) {
          if (state is TicketUpdated) {
            ctx.read<TicketBloc>().add(LoadTicketDetail(widget.ticketId));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Tiket diperbarui'), backgroundColor: Colors.green),
            );
          }
        },
        builder: (ctx, state) {
          if (state is TicketLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TicketError) {
            return Center(child: Text(state.message));
          }
          if (state is TicketDetailLoaded) {
            final t = state.ticket;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header info tiket
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _Badge(label: t.statusLabel, color: _statusColor(t.status)),
                                  const SizedBox(width: 8),
                                  _Badge(label: t.priorityLabel, color: _priorityColor(t.priority)),
                                ],
                              ),
                              const Divider(height: 24),
                              Text('Deskripsi', style: theme.textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(t.description, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 14,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dibuat: ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Attachments
                      if (t.attachmentUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Lampiran', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: t.attachmentUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                t.attachmentUrls[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Admin: Assign tiket
                      if (isHelpdesk) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: Text(t.assignedTo == null
                              ? 'Assign ke Helpdesk'
                              : 'Reassign Tiket'),
                          onPressed: () {
                            // TODO: tampilkan dialog pilih helpdesk
                          },
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text('Komentar',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Placeholder komentar (dari API nanti)
                      ...List.generate(
                        2,
                        (i) => _CommentBubble(
                          name: i == 0 ? 'User Demo' : 'Helpdesk 1',
                          content: i == 0
                              ? 'Komputer saya tidak bisa menyala sejak tadi pagi.'
                              : 'Baik, kami akan segera menindaklanjuti laporan Anda.',
                          isHelpdesk: i == 1,
                          time: '10:${30 + i * 5}',
                        ),
                      ),
                    ],
                  ),
                ),

                // Input komentar
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Tulis komentar...',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendComment,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      );
}

class _CommentBubble extends StatelessWidget {
  final String name, content, time;
  final bool isHelpdesk;
  const _CommentBubble({
    required this.name,
    required this.content,
    required this.time,
    required this.isHelpdesk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isHelpdesk
                ? AppColors.secondary.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.15),
            child: Text(
              name[0],
              style: TextStyle(
                color: isHelpdesk ? AppColors.secondary : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (isHelpdesk) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Helpdesk',
                            style: TextStyle(
                                color: AppColors.secondary, fontSize: 10)),
                      ),
                    ],
                    const Spacer(),
                    Text(time,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(content, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}