import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tampilan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.themeMode,
              builder: (context, mode, _) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: (m) {
                        if (m != null) ThemeController.setThemeMode(m);
                      },
                      title: const Text('Mode Terang'),
                      secondary: const Icon(Icons.light_mode_outlined),
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: (m) {
                        if (m != null) ThemeController.setThemeMode(m);
                      },
                      title: const Text('Mode Gelap'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: (m) {
                        if (m != null) ThemeController.setThemeMode(m);
                      },
                      title: const Text('Ikuti Sistem'),
                      subtitle: const Text(
                          'Otomatis menyesuaikan pengaturan perangkat'),
                      secondary: const Icon(Icons.brightness_auto_outlined),
                      activeColor: AppColors.primary,
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Tentang',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Versi Aplikasi'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.school_outlined),
                  title: Text('E-Ticketing Helpdesk'),
                  subtitle: Text(
                    'Praktikum Mobile - DIV Teknik Informatika\nUniversitas Airlangga',
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