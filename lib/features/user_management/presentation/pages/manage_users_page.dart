import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  String _roleFilter = 'Semua';

  final _roleOptions = ['Semua', 'user', 'helpdesk', 'admin'];
  final _roleLabels = {
    'Semua': 'Semua',
    'user': 'Pengguna',
    'helpdesk': 'Helpdesk',
    'admin': 'Admin',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('users')
          .select('id, name, email, role, is_active, created_at')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = _users;

    if (_roleFilter != 'Semua') {
      list = list.where((u) => u['role'] == _roleFilter).toList();
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((u) {
        final name = (u['name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    return list;
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final newValue = !(user['is_active'] as bool? ?? true);
    final name = user['name'] as String? ?? 'Pengguna';

    try {
      await _supabase
          .from('users')
          .update({'is_active': newValue})
          .eq('id', user['id'] as String);

      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) {
          _users[idx] = {..._users[idx], 'is_active': newValue};
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? '$name telah diaktifkan kembali'
              : '$name telah dinonaktifkan'),
          backgroundColor: newValue ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    }
  }

  Future<void> _confirmToggleActive(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool? ?? true;
    final name = user['name'] as String? ?? 'Pengguna';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? 'Nonaktifkan Pengguna?' : 'Aktifkan Pengguna?'),
        content: Text(
          isActive
              ? '$name tidak akan bisa login ke aplikasi setelah dinonaktifkan. Lanjutkan?'
              : '$name akan bisa login kembali ke aplikasi. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _toggleActive(user);
    }
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final currentRole = user['role'] as String? ?? 'user';
    final name = user['name'] as String? ?? 'Pengguna';

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ubah Role - $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['user', 'helpdesk', 'admin'].map((role) {
            final isSelected = role == currentRole;
            return ListTile(
              leading: Icon(
                _roleIcon(role),
                color: _roleColor(role),
              ),
              title: Text(_roleLabels[role] ?? role),
              trailing: isSelected ? const Icon(Icons.check) : null,
              tileColor: isSelected
                  ? _roleColor(role).withValues(alpha: 0.08)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, role),
            );
          }).toList(),
        ),
      ),
    );

    if (selected == null || selected == currentRole) return;

    try {
      await _supabase
          .from('users')
          .update({'role': selected})
          .eq('id', user['id'] as String);

      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) {
          _users[idx] = {..._users[idx], 'role': selected};
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Role $name diubah menjadi ${_roleLabels[selected]}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah role: $e')),
      );
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.priorityCritical;
      case 'helpdesk':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'helpdesk':
        return Icons.support_agent_outlined;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _roleOptions.map((r) {
                      final selected = _roleFilter == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_roleLabels[r]!),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _roleFilter = r),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
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
              TextButton(onPressed: _loadUsers, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final list = _filteredUsers;

    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tidak ada pengguna ditemukan'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final user = list[i];
          final name = user['name'] as String? ?? '-';
          final email = user['email'] as String? ?? '-';
          final role = user['role'] as String? ?? 'user';
          final isActive = user['is_active'] as bool? ?? true;
          final roleColor = _roleColor(role);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: roleColor.withValues(alpha: 0.15),
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1) : '?',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Nonaktif',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _changeRole(user),
                          icon: Icon(_roleIcon(role), size: 16),
                          label: Text(_roleLabels[role] ?? role),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: roleColor,
                            side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmToggleActive(user),
                          icon: Icon(
                            isActive
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isActive ? Colors.red : Colors.green,
                            side: BorderSide(
                              color: (isActive ? Colors.red : Colors.green)
                                  .withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}