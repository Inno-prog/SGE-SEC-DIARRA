import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';

// ─── Reports ─────────────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      ('Rapport des présences', Icons.fingerprint, AppColors.primary),
      ('Rapport des salaires', Icons.payments_outlined, AppColors.success),
      ('Rapport des congés', Icons.beach_access_outlined, AppColors.info),
      ('Rapport des employés', Icons.people_outline, AppColors.accent),
      ('Rapport des sanctions', Icons.gavel_outlined, AppColors.error),
      ('Rapport des formations', Icons.school_outlined, AppColors.warning),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rapports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Générer des rapports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Exportez vos données en PDF ou Excel',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...reports.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: r.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.$2, color: r.$3),
                ),
                title: Text(
                  r.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: AppColors.error,
                      ),
                      onPressed: () =>
                          showSnack(context, 'Génération PDF en cours...'),
                      tooltip: 'PDF',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.table_chart_outlined,
                        color: AppColors.success,
                      ),
                      onPressed: () =>
                          showSnack(context, 'Génération Excel en cours...'),
                      tooltip: 'Excel',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Journal des actions'),
          const SizedBox(height: 12),
          Consumer(
            builder: (_, ref, __) {
              final logs = ref.watch(auditLogsProvider);
              return logs.when(
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        message: 'Aucune action enregistrée',
                        icon: Icons.history,
                      )
                    : Column(
                        children: list
                            .take(20)
                            .map(
                              (l) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _actionColor(
                                          l.action,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        _actionIcon(l.action),
                                        color: _actionColor(l.action),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Par ${l.userNom} • ${DateFormat('dd/MM/yyyy HH:mm').format(l.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const LoadingWidget(),
                error: (e, _) => Center(
                  child: Text(
                    "Erreur: $e",
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'ajout':
        return AppColors.success;
      case 'modification':
        return AppColors.warning;
      case 'suppression':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'ajout':
        return Icons.add_circle_outline;
      case 'modification':
        return Icons.edit_outlined;
      case 'suppression':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }
}

// ─── Settings ────────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Cabinet',
            items: [
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Informations du cabinet',
                onTap: () {},
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
                  value: false,
                  onChanged: (_) {},
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
                  value: true,
                  onChanged: (_) {},
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
              trailing: const Text(
                AppConstants.appVersion,
                style: TextStyle(color: AppColors.textSecondary),
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

// ─── Security ────────────────────────────────────────────────────────────────
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      showSnack(
        context,
        'Les mots de passe ne correspondent pas',
        isError: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).updatePassword(_newPassCtrl.text);
      if (mounted) {
        showSnack(context, 'Mot de passe modifié avec succès');
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sécurité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Changer le mot de passe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  AppTextField(
                    label: 'Ancien mot de passe',
                    controller: _oldPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Nouveau mot de passe',
                    controller: _newPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _changePassword,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Modifier le mot de passe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Double authentification (2FA)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    title: const Text('Activer le 2FA'),
                    subtitle: const Text(
                      'Sécurisez votre compte avec une vérification en deux étapes',
                    ),
                    value: user.twoFactorEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) async {
                      await ref
                          .read(authServiceProvider)
                          .updateUser(user.copyWith(twoFactorEnabled: v));
                      if (context.mounted)
                        showSnack(context, v ? '2FA activé' : '2FA désactivé');
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journal de connexion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login, color: AppColors.success),
                    title: const Text('Dernière connexion'),
                    subtitle: Text(
                      user.lastLogin != null
                          ? DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(user.lastLogin!)
                          : 'Inconnue',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Users ───────────────────────────────────────────────────────────────────
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Utilisateurs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nouvel utilisateur'),
      ),
      body: users.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                message: 'Aucun utilisateur',
                icon: Icons.manage_accounts_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _UserTile(user: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [UserModel? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserForm(user: user),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final UserModel user;
  const _UserTile({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case AppConstants.roleAdmin:
        return AppColors.error;
      case AppConstants.roleRH:
        return AppColors.primary;
      case AppConstants.roleDirector:
        return AppColors.gold;
      case AppConstants.roleChefService:
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: EmployeeAvatar(
          photoUrl: user.photoUrl,
          name: user.fullName,
          radius: 24,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.role,
                style: TextStyle(
                  color: _roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'toggle') {
                  await ref
                      .read(authServiceProvider)
                      .updateUser(user.copyWith(isActive: !user.isActive));
                  if (context.mounted)
                    showSnack(
                      context,
                      user.isActive
                          ? 'Utilisateur désactivé'
                          : 'Utilisateur activé',
                    );
                } else if (v == 'delete') {
                  final ok = await showConfirm(
                    context,
                    title: 'Supprimer',
                    message: 'Supprimer l\'utilisateur ${user.fullName} ?',
                  );
                  if (ok && context.mounted) {
                    await ref.read(authServiceProvider).deleteUser(user.id);
                    if (context.mounted)
                      showSnack(context, 'Utilisateur supprimé');
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(user.isActive ? 'Désactiver' : 'Activer'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Supprimer',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  final UserModel? user;
  const _UserForm({this.user});

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = AppConstants.roleEmployee;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nomCtrl.text = widget.user!.nom;
      _prenomCtrl.text = widget.user!.prenom;
      _emailCtrl.text = widget.user!.email;
      _role = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (widget.user != null) {
        await ref
            .read(authServiceProvider)
            .updateUser(
              widget.user!.copyWith(
                nom: _nomCtrl.text,
                prenom: _prenomCtrl.text,
                role: _role,
              ),
            );
      } else {
        await ref
            .read(authServiceProvider)
            .createUser(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text,
              nom: _nomCtrl.text.trim(),
              prenom: _prenomCtrl.text.trim(),
              role: _role,
            );
      }
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Utilisateur enregistré');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.user == null
                  ? 'Nouvel utilisateur'
                  : 'Modifier l\'utilisateur',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Nom *',
                    controller: _nomCtrl,
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Prénom *',
                    controller: _prenomCtrl,
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.user == null) ...[
              AppTextField(
                label: 'Email *',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Mot de passe *',
                controller: _passCtrl,
                obscureText: true,
                validator: (v) =>
                    (v?.length ?? 0) < 6 ? 'Min 6 caractères' : null,
              ),
              const SizedBox(height: 12),
            ],
            AppDropdown<String>(
              label: 'Rôle',
              value: _role,
              items: [
                AppConstants.roleAdmin,
                AppConstants.roleRH,
                AppConstants.roleDirector,
                AppConstants.roleChefService,
                AppConstants.roleEmployee,
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: const Text('Enregistrer'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
