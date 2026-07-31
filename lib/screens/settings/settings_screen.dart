import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Cabinet',
            items: [
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Informations du cabinet',
                onTap: () async {
                  final uri = Uri.parse('https://diarrasec.com/burkina/presentationburkina');
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.image_outlined,
                title: 'Logo',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.attach_money_outlined,
                title: 'Devise',
                subtitle: 'FCFA',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.access_time_outlined,
                title: 'Fuseau horaire',
                subtitle: 'Burkina Faso/Ouagadougou',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Apparence',
            items: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Couleurs',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Mode sombre',
                trailing: Switch(
                  value: user?.darkMode ?? false,
                  onChanged: (v) async {
                    final current = ref.read(currentUserProvider);
                    if (current == null) return;
                    ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                    await ref.read(authServiceProvider).updateUser(current.copyWith(darkMode: v));
                    ref.invalidate(authStateProvider);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Données',
            items: [
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Sauvegarde automatique',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Exporter les données',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                title: 'Restaurer une sauvegarde',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            items: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications push',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Notifications email',
                trailing: Switch(
                  value: user?.emailNotifications ?? true,
                  onChanged: (v) async {
                    final current = ref.read(currentUserProvider);
                    if (current == null) return;
                    await ref.read(authServiceProvider).updateUser(current.copyWith(emailNotifications: v));
                    ref.invalidate(authStateProvider);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Version'),
              trailing: Text(
                '1.0.0',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < items.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}
