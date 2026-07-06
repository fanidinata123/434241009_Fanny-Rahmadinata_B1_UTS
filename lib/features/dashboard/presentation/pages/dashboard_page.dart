import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ticket/presentation/bloc/ticket_bloc.dart';
import '../../../ticket/presentation/pages/ticket_list_page.dart';
import '../../../ticket/presentation/pages/create_ticket_page.dart';
import '../../../ticket/presentation/pages/riwayat_page.dart';
import '../../../notification/presentation/pages/notification_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../user_management/presentation/pages/manage_users_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  Key _notifKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(LoadTicketStats());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isHelpdesk = user?.isHelpdesk ?? false;
    final isAdmin = user?.isAdmin ?? false;

    final pages = [
      _HomeContent(user: user, isHelpdesk: isHelpdesk, isAdmin: isAdmin),
      const TicketListPage(),
      CreateTicketPage(
        onTicketCreated: () {
          setState(() => _currentIndex = 0);
          context.read<TicketBloc>().add(LoadTicketStats());
        },
      ),
      NotificationPage(key: _notifKey),
      const ProfilePage(),
    ];

    const notifIndex = 3;

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() {
            _currentIndex = i;
            if (i == notifIndex) {
              _notifKey = UniqueKey();
            }
          });
          if (i == 0) {
            context.read<TicketBloc>().add(LoadTicketStats());
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Buat Tiket',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final UserEntity? user;
  final bool isHelpdesk;
  final bool isAdmin;

  const _HomeContent({
    this.user,
    required this.isHelpdesk,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<TicketBloc>().add(LoadTicketStats());
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  BlocBuilder<TicketBloc, TicketState>(
                    builder: (context, state) {
                      Map<String, int> stats = const {
                        'total': 0,
                        'open': 0,
                        'in_progress': 0,
                        'resolved': 0,
                        'closed': 0,
                      };

                      Widget? extra;

                      if (state is TicketStatsLoading) {
                        extra = const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (state is TicketStatsLoaded) {
                        stats = state.stats;
                      } else if (state is TicketStatsError) {
                        extra = Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Gagal memuat statistik: ${state.message}',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatCard(context, stats),
                          const SizedBox(height: 20),
                          Text(
                            'Status Tiket',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (extra != null) extra,
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.0,
                            children: [
                              _StatusCard(
                                label: 'Dibuka',
                                count: stats['open'] ?? 0,
                                color: AppColors.statusOpen,
                                icon: Icons.fiber_new_rounded,
                              ),
                              _StatusCard(
                                label: 'Diproses',
                                count: stats['in_progress'] ?? 0,
                                color: AppColors.statusInProgress,
                                icon: Icons.timelapse_rounded,
                              ),
                              _StatusCard(
                                label: 'Selesai',
                                count: stats['resolved'] ?? 0,
                                color: AppColors.statusResolved,
                                icon: Icons.check_circle_rounded,
                              ),
                              _StatusCard(
                                label: 'Ditutup',
                                count: stats['closed'] ?? 0,
                                color: AppColors.statusClosed,
                                icon: Icons.cancel_rounded,
                              ),
                            ],
                          ),

                          // Bar Chart
                          const SizedBox(height: 16),
                          _TicketBarChart(stats: stats),

                          // Tombol aksi untuk helpdesk/admin (tanpa judul)
                          if (isHelpdesk) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // Assign Tiket — khusus admin
                                if (isAdmin) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.assignment_ind_outlined),
                                      label: const Text('Assign Tiket'),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Assign Tiket'),
                                          content: const Text(
                                              'Buka Daftar Tiket, pilih tiket yang ingin di-assign, lalu tap untuk assign ke helpdesk.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Mengerti'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                // Riwayat — admin & helpdesk
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.history),
                                    label: const Text('Riwayat'),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RiwayatPage(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Kelola Pengguna — khusus admin
                            if (isAdmin) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.people_outline),
                                  label: const Text('Kelola Pengguna'),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ManageUsersPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Tiket',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats['total'] ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.confirmation_number,
            color: Colors.white38,
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart Widget ─────────────────────────────────────────────────
class _TicketBarChart extends StatelessWidget {
  final Map<String, int> stats;

  const _TicketBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats['total'] ?? 0;

    final bars = [
      _BarData('Dibuka',   stats['open'] ?? 0,        AppColors.statusOpen),
      _BarData('Diproses', stats['in_progress'] ?? 0, AppColors.statusInProgress),
      _BarData('Selesai',  stats['resolved'] ?? 0,    AppColors.statusResolved),
      _BarData('Ditutup',  stats['closed'] ?? 0,      AppColors.statusClosed),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Statistik Tiket',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                final pct = total == 0 ? 0.0 : bar.value / total;
                final maxH = 120.0;
                final barH = (pct * maxH).clamp(4.0, maxH);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        // Nilai
                        Text(
                          '${bar.value}',
                          style: TextStyle(
                            color: bar.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: barH,
                          decoration: BoxDecoration(
                            color: bar.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Label
                        Text(
                          bar.label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Persentase kecil di bawah
            Row(
              children: bars.map((bar) {
                final pct = total == 0
                    ? 0
                    : ((bar.value / total) * 100).round();
                return Expanded(
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: bar.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}