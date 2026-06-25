import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/ticket_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'tracking_page.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _commentCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  // Komentar diambil dari tabel `comments`, di-join dengan `users`
  // untuk mendapatkan nama dan role pengirim.
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTicketDetail(widget.ticketId));
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });

    try {
      final data = await _supabase
          .from('comments')
          .select('id, content, created_at, users:user_id ( name, role )')
          .eq('ticket_id', widget.ticketId)
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(data as List);

      setState(() {
        _comments = rows.map((row) {
          final user = row['users'] as Map<String, dynamic>?;
          final role = user?['role'] as String?;
          return {
            'name': user?['name'] as String? ?? 'Pengguna',
            'content': row['content'] as String? ?? '',
            'isHelpdesk': role == 'helpdesk' || role == 'admin',
            'roleLabel': role == 'admin' ? 'Admin' : 'Helpdesk',
            'time': DateFormatter.format(
              DateTime.parse(row['created_at'] as String),
            ),
          };
        }).toList();
        _loadingComments = false;
      });
    } catch (e) {
      setState(() {
        _commentsError = e.toString();
        _loadingComments = false;
      });
    }
  }

  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    _commentCtrl.clear();
    context.read<TicketBloc>().add(AddComment(widget.ticketId, text));
  }

  Future<void> _confirmDelete() async {
    final state = context.read<TicketBloc>().state;
    final title = state is TicketDetailLoaded ? state.ticket.title : 'tiket ini';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tiket?'),
        content: Text(
          'Tiket "$title" beserta seluruh komentar dan riwayatnya akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<TicketBloc>().add(DeleteTicket(widget.ticketId));
    }
  }

  void _showStatusDialog(TicketEntity ticket) {
    final statusOptions = [
      {'value': 'open',       'label': 'Dibuka',   'color': AppColors.statusOpen},
      {'value': 'inProgress', 'label': 'Diproses', 'color': AppColors.statusInProgress},
      {'value': 'resolved',   'label': 'Selesai',  'color': AppColors.statusResolved},
      {'value': 'closed',     'label': 'Ditutup',  'color': AppColors.statusClosed},
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Status Tiket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((s) {
            final isSelected = ticket.status.name == s['value'];
            final color = s['color'] as Color;
            return ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: color,
              ),
              title: Text(s['label'] as String),
              trailing: isSelected
                  ? Icon(Icons.check, color: color)
                  : null,
              tileColor: isSelected ? color.withValues(alpha: 0.08) : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.pop(context);
                context.read<TicketBloc>().add(
                      UpdateTicketStatus(widget.ticketId, s['value'] as String),
                    );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showAssignDialog() async {
    // Tampilkan loading sementara fetch daftar helpdesk
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> helpdesks = [];
    String? error;

    try {
      final data = await _supabase
          .from('users')
          .select('id, name')
          .eq('role', 'helpdesk')
          .eq('is_active', true)
          .order('name');
      helpdesks = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    Navigator.pop(context); // tutup loading dialog

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar helpdesk: $error')),
      );
      return;
    }

    if (helpdesks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada helpdesk yang tersedia')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign ke Helpdesk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: helpdesks.map((h) {
            final name = h['name'] as String? ?? 'Helpdesk';
            final id = h['id'] as String;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1) : '?',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
              title: Text(name),
              subtitle: const Text('Helpdesk'),
              onTap: () {
                Navigator.pop(context);
                context.read<TicketBloc>().add(
                      AssignTicket(widget.ticketId, id),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tiket di-assign ke $name'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:       return AppColors.statusOpen;
      case TicketStatus.inProgress: return AppColors.statusInProgress;
      case TicketStatus.resolved:   return AppColors.statusResolved;
      case TicketStatus.closed:     return AppColors.statusClosed;
    }
  }

  Color _priorityColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.low:      return AppColors.priorityLow;
      case TicketPriority.medium:   return AppColors.priorityMedium;
      case TicketPriority.high:     return AppColors.priorityHigh;
      case TicketPriority.critical: return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isHelpdesk =
        authState is AuthAuthenticated && authState.user.isHelpdesk;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          // Tombol Tracking untuk semua user
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            tooltip: 'Tracking',
            onPressed: () {
              final state = context.read<TicketBloc>().state;
              final title = state is TicketDetailLoaded
                  ? state.ticket.title
                  : 'Tiket';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackingPage(
                    ticketId: widget.ticketId,
                    ticketTitle: title,
                  ),
                ),
              );
            },
          ),
          // Tombol edit status untuk helpdesk/admin
          if (isHelpdesk)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Status',
              onPressed: () {
                final state = context.read<TicketBloc>().state;
                if (state is TicketDetailLoaded) {
                  _showStatusDialog(state.ticket);
                }
              },
            ),
          // Tombol hapus tiket khusus admin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Tiket',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: BlocConsumer<TicketBloc, TicketState>(
        listener: (ctx, state) {
          if (state is TicketUpdated) {
            ctx.read<TicketBloc>().add(LoadTicketDetail(widget.ticketId));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Tiket diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TicketDeleted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Tiket berhasil dihapus'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(ctx);
          } else if (state is TicketDetailLoaded) {
            // Setelah komentar dikirim, TicketBloc memicu reload detail
            // tiket (LoadTicketDetail). Manfaatkan momen ini untuk
            // sekaligus refresh daftar komentar dari Supabase.
            _loadComments();
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
                      // Info tiket
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _Badge(
                                    label: t.statusLabel,
                                    color: _statusColor(t.status),
                                  ),
                                  const SizedBox(width: 8),
                                  _Badge(
                                    label: t.priorityLabel,
                                    color: _priorityColor(t.priority),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text('Deskripsi',
                                  style: theme.textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(t.description,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dibuat: ${DateFormatter.format(t.createdAt)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Assign tiket (helpdesk/admin)
                      if (isHelpdesk) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: Text(t.assignedTo == null
                              ? 'Assign ke Helpdesk'
                              : 'Reassign Tiket'),
                          onPressed: _showAssignDialog,
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Komentar (${_comments.length})',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_loadingComments) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_commentsError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Gagal memuat komentar: $_commentsError',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        )
                      else if (!_loadingComments && _comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Belum ada komentar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),

                      ..._comments.map(
                        (c) => _CommentBubble(
                          name: c['name'],
                          content: c['content'],
                          isHelpdesk: c['isHelpdesk'],
                          roleLabel: c['roleLabel'] ?? 'Helpdesk',
                          time: c['time'],
                        ),
                      ),
                    ],
                  ),
                ),

                // Input komentar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

class _CommentBubble extends StatelessWidget {
  final String name, content, time;
  final bool isHelpdesk;
  final String roleLabel;
  const _CommentBubble({
    required this.name,
    required this.content,
    required this.time,
    required this.isHelpdesk,
    this.roleLabel = 'Helpdesk',
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
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '?',
              style: TextStyle(
                color:
                    isHelpdesk ? AppColors.secondary : AppColors.primary,
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
                    Text(
                      name,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isHelpdesk) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                              color: AppColors.secondary, fontSize: 10),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    content,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}