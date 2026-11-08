import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Utilisateurs'),
        actions: [NotificationBell()],
      ),
      body: users.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((u) =>
                    u.fullName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.role.toLowerCase().contains(q))
                .toList();
          }

          return _UsersPageContent(
            users: filtered,
            search: _search,
            onSearch: (v) => setState(() => _search = v),
            onAdd: () => _showForm(context, ref),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [UserModel? user]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _UserForm(user: user),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _UsersPageContent extends ConsumerWidget {
  final List<UserModel> users;
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;

  const _UsersPageContent({
    required this.users,
    required this.search,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canDelete = currentUser != null &&
        (currentUser.role == AppConstants.roleAdmin);

    // Build columns inside build method to have access to context and ref
    final columns = _buildColumns(canDelete: canDelete, context: context, ref: ref);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page Header
            ProPageHeader(
              icon: Icons.manage_accounts_outlined,
              title: 'Liste des utilisateurs',
              subtitle: 'Gestion des comptes et accès utilisateurs',
              count: users.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher par nom, email, rôle...',
              onSearch: onSearch,
              addLabel: 'Nouvel utilisateur',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<UserModel>(
              minWidth: 1100,
              columns: columns,
              items: users,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<UserModel>> _buildColumns({
    required bool canDelete,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return [
      ProColumn<UserModel>(
        label: 'Utilisateur',
        flex: 3,
        cell: (u) => ProEmployeeCell(
          name: u.fullName,
          subtitle: u.email,
        ),
      ),
      ProColumn<UserModel>(
        label: 'Rôle',
        flex: 2,
        alignment: Alignment.center,
        cell: (u) => _buildRoleChip(u.role),
      ),
      ProColumn<UserModel>(
        label: 'Statut',
        flex: 2,
        alignment: Alignment.center,
        cell: (u) => ProStatusChip(
          label: u.isActive ? 'Actif' : 'Inactif',
          color: u.isActive ? AppColors.success : Colors.grey,
        ),
      ),
      ProColumn<UserModel>(
        label: '2FA',
        flex: 2,
        alignment: Alignment.center,
        cell: (u) => ProStatusChip(
          label: u.twoFactorEnabled ? 'Activé' : 'Désactivé',
          color: u.twoFactorEnabled ? AppColors.info : Colors.grey,
          icon: u.twoFactorEnabled ? Icons.security : Icons.security_outlined,
        ),
      ),
      ProColumn<UserModel>(
        label: 'Créé le',
        flex: 2,
        alignment: Alignment.center,
        cell: (u) => Text('${u.createdAt.day.toString().padLeft(2, '0')}/${u.createdAt.month.toString().padLeft(2, '0')}/${u.createdAt.year}'),
      ),
      ProColumn<UserModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (u) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () => _showForm(context, ref, u),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: u.isActive ? Icons.lock_outline : Icons.lock_open_outlined,
              color: u.isActive ? AppColors.success : Colors.red.shade700,
              tooltip: u.isActive ? 'Désactiver' : 'Activer',
              onTap: () async {
                await ref.read(userApiServiceProvider).updateUserStatus(u.id, !u.isActive);
                if (context.mounted) {
                  ref.invalidate(usersProvider);
                  showSnack(context, u.isActive ? 'Utilisateur désactivé' : 'Utilisateur activé');
                }
              },
            ),
            if (canDelete) ...[
              const SizedBox(width: 8),
              ProActionIcon(
                icon: Icons.delete_outline,
                color: Colors.red.shade700,
                tooltip: 'Supprimer',
                onTap: () async {
                  final ok = await showConfirm(
                    context,
                    title: 'Supprimer',
                    message: 'Supprimer l\'utilisateur ${u.fullName} ?',
                  );
                  if (ok && context.mounted) {
                    await ref.read(userApiServiceProvider).deleteUser(u.id);
                    if (context.mounted) {
                      ref.invalidate(usersProvider);
                      showSnack(context, 'Utilisateur supprimé');
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role) {
      case AppConstants.roleAdmin:
        color = Colors.red.shade700;
        break;
      case AppConstants.roleDirector:
        color = Colors.purple.shade700;
        break;
      case AppConstants.roleRH:
        color = Colors.blue.shade700;
        break;
      case AppConstants.roleChefService:
        color = Colors.teal.shade700;
        break;
      case AppConstants.roleEmployee:
        color = Colors.grey.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }
    return ProStatusChip(label: role, color: color);
  }

  void _showForm(BuildContext context, WidgetRef ref, [UserModel? user]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _UserForm(user: user),
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
      final userService = ref.read(userApiServiceProvider);
      if (widget.user != null) {
        await userService.updateUser(widget.user!.id, widget.user!.copyWith(nom: _nomCtrl.text, prenom: _prenomCtrl.text, role: _role));
      } else {
        await userService.createUser(
          UserModel(
            id: '',
            email: _emailCtrl.text.trim(),
            nom: _nomCtrl.text.trim(),
            prenom: _prenomCtrl.text.trim(),
            role: _role,
            isActive: true,
            twoFactorEnabled: false,
            mustChangePassword: true,
            createdAt: DateTime.now(),
          ),
          password: _passCtrl.text,
        );
      }
      if (mounted) {
        ref.invalidate(usersProvider);
        Navigator.pop(context);
        showSnack(context, 'Utilisateur enregistré');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.user == null ? 'Nouvel utilisateur' : 'Modifier l\'utilisateur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Nom *', controller: _nomCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(label: 'Prénom *', controller: _prenomCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null)),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.user == null) ...[
                AppTextField(label: 'Email *', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                AppTextField(label: 'Mot de passe *', controller: _passCtrl, obscureText: true, validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 caractères' : null),
                const SizedBox(height: 12),
              ],
              AppDropdown<String>(
                label: 'Rôle',
                value: _role,
                items: [AppConstants.roleAdmin, AppConstants.roleRH, AppConstants.roleDirector, AppConstants.roleChefService, AppConstants.roleEmployee]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}