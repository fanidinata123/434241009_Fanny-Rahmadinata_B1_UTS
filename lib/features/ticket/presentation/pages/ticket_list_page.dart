import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/ticket_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  String? _selectedStatus;
  String? _selectedHelpdeskId;
  final _searchCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _helpdeskList = [];
  bool _loadingHelpdesk = false;

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTickets());
    _maybeLoadHelpdeskList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  final _statusOptions = ['Semua', 'open', 'inProgress', 'resolved', 'closed'];
  final _statusLabels = {
    'Semua': 'Semua',
    'open': 'Dibuka',
    'inProgress': 'Diproses',
    'resolved': 'Selesai',
    'closed': 'Ditutup',
  };

  bool get _isAdmin {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.isAdmin;
  }

  Future<void> _maybeLoadHelpdeskList() async {
    if (!_isAdmin) return;
    setState(() => _loadingHelpdesk = true);
    try {
      final data = await _supabase
          .from('users')
          .select('id, name')
          .eq('role', 'helpdesk')
          .eq('is_active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _helpdeskList = List<Map<String, dynamic>>.from(data as List);
        _loadingHelpdesk = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHelpdesk = false);
    }
  }

  void _applyFilter() {
    context.read<TicketBloc>().add(LoadTickets(
          statusFilter: _selectedStatus == 'Semua' ? null : _selectedStatus,
          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
          assignedTo: _selectedHelpdeskId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TicketBloc>().add(LoadTickets(
                  statusFilter: _selectedStatus == 'Semua' ? null : _selectedStatus,
                  assignedTo: _selectedHelpdeskId,
                )),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isAdmin ? 148 : 100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari tiket...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, size: 18),
                      onPressed: _applyFilter,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statusOptions.map((s) {
                      final selected = _selectedStatus == s ||
                          (_selectedStatus == null && s == 'Semua');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_statusLabels[s]!),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedStatus = s == 'Semua' ? null : s);
                            _applyFilter();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _loadingHelpdesk
                        ? const Center(
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: _selectedHelpdeskId,
                              icon: const Icon(Icons.support_agent_outlined, size: 18),
                              hint: const Text('Filter per Helpdesk', style: TextStyle(fontSize: 13)),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Semua Helpdesk'),
                                ),
                                ..._helpdeskList.map((h) => DropdownMenuItem<String?>(
                                      value: h['id'] as String,
                                      child: Text(h['name'] as String? ?? '-'),
                                    )),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedHelpdeskId = v);
                                _applyFilter();
                              },
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (ctx, state) {
          if (state is TicketLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TicketError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                  TextButton(
                    onPressed: () => ctx.read<TicketBloc>().add(LoadTickets()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          if (state is TicketListLoaded) {
            if (state.tickets.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada tiket'),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _TicketCard(
                ticket: state.tickets[i],
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailPage(ticketId: state.tickets[i].id),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(label: ticket.statusLabel, color: _statusColor(ticket.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.description,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(label: ticket.priorityLabel, color: _priorityColor(ticket.priority)),
                  const Spacer(),
                  Icon(Icons.schedule, size: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}