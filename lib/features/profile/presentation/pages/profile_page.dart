import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.admin:    return 'Admin';
      case UserRole.helpdesk: return 'Helpdesk';
      case UserRole.user:     return 'Pengguna';
    }
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.admin:    return AppColors.priorityCritical;
      case UserRole.helpdesk: return AppColors.secondary;
      case UserRole.user:     return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '-',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roleColor(user.role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _roleColor(user.role).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _roleLabel(user.role),
                      style: TextStyle(color: _roleColor(user.role), fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Pengaturan Akun'),
          _MenuItem(icon: Icons.person_outline, label: 'Edit Profil',
            onTap: () => _showEditProfilDialog(context, user)),
          _MenuItem(icon: Icons.lock_outline, label: 'Ganti Password',
            onTap: () => _showGantiPasswordDialog(context)),
          _MenuItem(icon: Icons.notifications_outlined, label: 'Pengaturan Notifikasi',
            onTap: () => showDialog(context: context, builder: (_) => const _NotifSettingDialog())),
          _MenuItem(icon: Icons.settings_outlined, label: 'Pengaturan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            )),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Tampilan'),
          const _ThemeToggle(),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Lainnya'),
          _MenuItem(
            icon: Icons.info_outline, label: 'Tentang Aplikasi',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'E-Ticketing Helpdesk',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.headset_mic_rounded),
              children: const [Text('Aplikasi pelaporan masalah IT\nUniversitas Airlangga')],
            ),
          ),
          _MenuItem(
            icon: Icons.logout_rounded, label: 'Keluar', color: Colors.red,
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Keluar'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditProfilDialog(BuildContext context, UserEntity? user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final supabase = Supabase.instance.client;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);

              try {
                // Update di tabel public.users
                await supabase
                    .from('users')
                    .update({'name': newName})
                    .eq('id', user?.id ?? '');

                // Update di SharedPreferences supaya langsung terlihat
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', newName);

                // Refresh AuthBloc supaya UI nama ikut berubah
                if (context.mounted) {
                  context.read<AuthBloc>().add(GetProfileRequested());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui profil: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showGantiPasswordDialog(BuildContext context) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => BlocConsumer<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthPasswordUpdated) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password berhasil diubah'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (ctx, state) => AlertDialog(
            title: const Text('Ganti Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newCtrl,
                  obscureText: !showNew,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDialogState(() => showNew = !showNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: !showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setDialogState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        final newPass = newCtrl.text.trim();
                        final confirm = confirmCtrl.text.trim();
                        if (newPass.isEmpty || confirm.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Semua field wajib diisi')),
                          );
                          return;
                        }
                        if (newPass != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Konfirmasi password tidak cocok')),
                          );
                          return;
                        }
                        if (newPass.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Password minimal 8 karakter')),
                          );
                          return;
                        }
                        ctx.read<AuthBloc>().add(
                            UpdatePasswordRequested(newPass));
                      },
                child: state is AuthLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifSettingDialog extends StatefulWidget {
  const _NotifSettingDialog();
  @override
  State<_NotifSettingDialog> createState() => _NotifSettingDialogState();
}

class _NotifSettingDialogState extends State<_NotifSettingDialog> {
  bool _updateStatus = true;
  bool _komentarBaru = true;
  bool _assignTiket = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Notifikasi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(title: const Text('Update Status Tiket'),
            subtitle: const Text('Notif saat status tiket berubah'),
            value: _updateStatus, onChanged: (v) => setState(() => _updateStatus = v)),
          SwitchListTile(title: const Text('Komentar Baru'),
            subtitle: const Text('Notif saat ada komentar baru'),
            value: _komentarBaru, onChanged: (v) => setState(() => _komentarBaru = v)),
          SwitchListTile(title: const Text('Assign Tiket'),
            subtitle: const Text('Notif saat tiket di-assign'),
            value: _assignTiket, onChanged: (v) => setState(() => _assignTiket = v)),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengaturan notifikasi disimpan'), backgroundColor: Colors.green));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 4),
    child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.5)),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: effectiveColor, size: 22),
        title: Text(label, style: TextStyle(color: effectiveColor)),
        trailing: Icon(Icons.chevron_right, size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Toggle cepat Mode Terang / Mode Gelap.
/// Sekarang benar-benar terhubung ke ThemeController (bukan lagi
/// state lokal kosmetik), sehingga perubahan langsung terlihat di
/// seluruh aplikasi dan tersimpan secara persisten.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              size: 22,
            ),
            title: Text(isDark ? 'Mode Gelap' : 'Mode Terang'),
            subtitle: mode == ThemeMode.system
                ? const Text('Saat ini mengikuti pengaturan sistem')
                : null,
            value: isDark,
            onChanged: (val) {
              ThemeController.setThemeMode(
                val ? ThemeMode.dark : ThemeMode.light,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Mode Gelap aktif' : 'Mode Terang aktif'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}