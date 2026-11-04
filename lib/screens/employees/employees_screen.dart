import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _search = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(allEmployeesProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Employés'),
        actions: [NotificationBell()],
      ),
      body: employees.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((e) =>
                    e.fullName.toLowerCase().contains(q) ||
                    e.matricule.toLowerCase().contains(q) ||
                    e.departementNom.toLowerCase().contains(q) ||
                    e.poste.toLowerCase().contains(q))
                .toList();
          }

          return _EmployeesPageContent(
            employees: filtered,
            search: _search,
            dateRange: _dateRange,
            onSearch: (v) => setState(() => _search = v),
            onDateFilter: (r) => setState(() => _dateRange = r),
            canEdit: canEdit,
            onView: (e) => context.go('/employees/${e.id}'),
            onEdit: canEdit ? (e) => context.go('/employees/${e.id}/edit') : null,
            onDelete: canEdit
                ? (e) async {
                    final ok = await showConfirm(
                      context,
                      title: 'Supprimer l\'employé',
                      message: 'Voulez-vous vraiment supprimer ${e.fullName} ?',
                    );
                    if (ok && context.mounted) {
                      await ref.read(employeeApiServiceProvider).deleteEmployee(e.id);
                      if (context.mounted) showSnack(context, 'Employé supprimé');
                    }
                  }
                : null,
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

/// Page content using new Pro components
class _EmployeesPageContent extends ConsumerWidget {
  final List<EmployeeModel> employees;
  final String search;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSearch;
  final ValueChanged<DateTimeRange?> onDateFilter;
  final bool canEdit;
  final void Function(EmployeeModel) onView;
  final void Function(EmployeeModel)? onEdit;
  final void Function(EmployeeModel)? onDelete;

  const _EmployeesPageContent({
    required this.employees,
    required this.search,
    required this.dateRange,
    required this.onSearch,
    required this.onDateFilter,
    required this.canEdit,
    required this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page Header
            ProPageHeader(
              icon: Icons.people_outline,
              title: 'Liste des employés',
              subtitle: 'Gestion du personnel de l\'entreprise',
              count: employees.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher par nom, matricule, poste...',
              onSearch: onSearch,
              onFilterDate: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: dateRange,
                );
                onDateFilter(picked);
              },
              addLabel: 'Ajouter un employé',
              onAdd: () => context.go('/employees/add'),
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<EmployeeModel>(
              minWidth: 1100,
              columns: _buildColumns(),
              items: employees,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<EmployeeModel>> _buildColumns() {
    return [
      ProColumn<EmployeeModel>(
        label: 'Matricule',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => Text(
          e.matricule,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      ProColumn<EmployeeModel>(
        label: 'Employé',
        flex: 4,
        cell: (e) => ProEmployeeCell(
          name: e.fullName,
          subtitle: e.poste,
        ),
      ),
      ProColumn<EmployeeModel>(
        label: 'Email',
        flex: 3,
        cell: (e) => Text(
          e.email,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      ProColumn<EmployeeModel>(
        label: 'Téléphone',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => Text(
          e.telephone.isEmpty ? '—' : e.telephone,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      ProColumn<EmployeeModel>(
        label: 'Département',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => ProStatusChip(label: e.departementNom, color: Colors.blue.shade700),
      ),
      ProColumn<EmployeeModel>(
        label: 'Type contrat',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => ProStatusChip(
          label: e.typeContrat,
          color: AppColors.primary,
        ),
      ),
      ProColumn<EmployeeModel>(
        label: 'Statut',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => _buildStatusChip(e.statut),
      ),
      ProColumn<EmployeeModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (e) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: Colors.blue.shade700,
              tooltip: 'Voir',
              onTap: () => onView(e),
            ),
            if (canEdit && onEdit != null) ...[
              const SizedBox(width: 8),
              ProActionIcon(
                icon: Icons.edit_outlined,
                color: Colors.orange.shade800,
                tooltip: 'Modifier',
                onTap: () => onEdit!(e),
              ),
            ],
            if (canEdit && onDelete != null) ...[
              const SizedBox(width: 8),
              ProActionIcon(
                icon: Icons.delete_outline,
                color: Colors.red.shade700,
                tooltip: 'Supprimer',
                onTap: () => onDelete!(e),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'actif':
        color = AppColors.success;
        break;
      case 'suspendu':
        color = AppColors.error;
        break;
      case 'demissionnaire':
        color = Colors.grey;
        break;
      case 'conge':
        color = AppColors.info;
        break;
      default:
        color = Colors.grey;
    }
    return ProStatusChip(label: status, color: color);
  }
}