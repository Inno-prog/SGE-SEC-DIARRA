import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/department_model.dart';
import '../../core/constants/app_constants.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final depts = ref.watch(departmentsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Départements'),
        actions: [NotificationBell()],
      ),
      body: depts.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((d) =>
                    d.nom.toLowerCase().contains(q) ||
                    (d.description?.toLowerCase().contains(q) ?? false) ||
                    (d.responsableNom?.toLowerCase().contains(q) ?? false))
                .toList();
          }

          return _DepartmentsPageContent(
            departments: filtered,
            onAdd: () => _showForm(context, ref),
            search: _search,
            onSearch: (v) => setState(() => _search = v),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [DepartmentModel? dept]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _DeptForm(dept: dept),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _DepartmentsPageContent extends ConsumerWidget {
  final List<DepartmentModel> departments;
  final VoidCallback onAdd;
  final String search;
  final ValueChanged<String> onSearch;

  const _DepartmentsPageContent({
    required this.departments,
    required this.onAdd,
    required this.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build columns inside build method to have access to context and ref
    final columns = _buildColumns(context: context, ref: ref);

    if (departments.isEmpty) {
      return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProPageHeader(
                icon: Icons.business_outlined,
                title: 'Liste des départements',
                subtitle: 'Gestion des départements de l\'entreprise',
                count: 0,
              ),
              const SizedBox(height: 16),
              ProListToolbar(
                searchHint: 'Rechercher un département...',
                onSearch: onSearch,
                addLabel: 'Nouveau département',
                onAdd: onAdd,
              ),
              const SizedBox(height: 16),
              const EmptyState(
                message: 'Aucun département',
                icon: Icons.business_outlined,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page Header
            ProPageHeader(
              icon: Icons.business_outlined,
              title: 'Liste des départements',
              subtitle: 'Gestion des départements de l\'entreprise',
              count: departments.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher un département...',
              onSearch: onSearch,
              addLabel: 'Nouveau département',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<DepartmentModel>(
              minWidth: 900,
              columns: columns,
              items: departments,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<DepartmentModel>> _buildColumns({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return [
      ProColumn<DepartmentModel>(
        label: 'Département',
        flex: 3,
        cell: (d) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_outlined, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                d.nom,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
      ProColumn<DepartmentModel>(
        label: 'Description',
        flex: 3,
        cell: (d) => Text(d.description?.isNotEmpty == true ? d.description! : '—', style: const TextStyle(color: AppColors.textSecondary)),
      ),
      ProColumn<DepartmentModel>(
        label: 'Responsable',
        flex: 2,
        alignment: Alignment.center,
        cell: (d) => d.responsableNom != null
            ? Text(d.responsableNom!, style: const TextStyle(fontWeight: FontWeight.w500))
            : const Text('—'),
      ),
      ProColumn<DepartmentModel>(
        label: 'Employés',
        flex: 2,
        alignment: Alignment.center,
        cell: (d) => Text('${d.nombreEmployes}'),
      ),
      ProColumn<DepartmentModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (d) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: AppColors.primary,
              tooltip: 'Voir',
              onTap: () => context.go('${AppRoutes.departments}/${d.id}'),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () => _showForm(context, ref, d),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () async {
                final ok = await showConfirm(
                  context,
                  title: 'Supprimer',
                  message: 'Supprimer le département "${d.nom}" ?',
                );
                if (ok && context.mounted) {
                  await ref.read(departmentApiServiceProvider).deleteDepartment(d.id);
                  if (context.mounted) showSnack(context, 'Département supprimé');
                }
              },
            ),
          ],
        ),
      ),
    ];
  }

  void _showForm(BuildContext context, WidgetRef ref, [DepartmentModel? dept]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _DeptForm(dept: dept),
        ),
      ),
    );
  }
}

class _DeptForm extends ConsumerStatefulWidget {
  final DepartmentModel? dept;
  const _DeptForm({this.dept});

  @override
  ConsumerState<_DeptForm> createState() => _DeptFormState();
}

class _DeptFormState extends ConsumerState<_DeptForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _responsableId;
  String? _responsableNom;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.dept != null) {
      _nomCtrl.text = widget.dept!.nom;
      _descCtrl.text = widget.dept!.description ?? '';
      _responsableId = widget.dept!.responsableId;
      _responsableNom = widget.dept!.responsableNom;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final departmentService = ref.read(departmentApiServiceProvider);
      if (widget.dept != null) {
        await departmentService.updateDepartment(
          widget.dept!.id,
          widget.dept!.copyWith(
            nom: _nomCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            responsableId: _responsableId,
            responsableNom: _responsableNom,
          ),
        );
      } else {
        await departmentService.createDepartment(
          DepartmentModel(
            id: '',
            nom: _nomCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            responsableId: _responsableId,
            responsableNom: _responsableNom,
            createdAt: DateTime.now(),
          ),
        );
      }
      if (mounted) {
        ref.invalidate(departmentsProvider);
        Navigator.pop(context);
        showSnack(context, 'Département enregistré');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersForResponsableProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.dept == null
                    ? 'Nouveau département'
                    : 'Modifier le département',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Nom *',
                controller: _nomCtrl,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              users.when(
                data: (list) {
                  // Validate that the current responsableId exists in the user list
                  // If not, reset to null to avoid dropdown assertion error
                  final validResponsableId = _responsableId != null && list.any((u) => u.id == _responsableId)
                      ? _responsableId
                      : null;
                  if (validResponsableId != _responsableId) {
                    // Use post-frame callback to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _responsableId = validResponsableId;
                          _responsableNom = validResponsableId != null
                              ? list.firstWhere((u) => u.id == validResponsableId).fullName
                              : null;
                        });
                      }
                    });
                  }

                  return AppDropdown<String>(
                    label: 'Responsable',
                    value: validResponsableId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Aucun')),
                      ...list.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.fullName),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      final user = v != null
                          ? list.firstWhere((u) => u.id == v)
                          : null;
                      setState(() {
                        _responsableId = v;
                        _responsableNom = user?.fullName;
                      });
                    },
                  );
                },
                loading: () => const SizedBox(),
                error: (e, _) => Center(
                  child: Text(
                    "Erreur: $e",
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}