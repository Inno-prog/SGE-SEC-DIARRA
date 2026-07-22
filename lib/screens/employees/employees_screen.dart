import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(filteredEmployeesProvider);
    final search = ref.watch(employeeSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/employees/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, matricule, poste...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            ref.read(employeeSearchProvider.notifier).state =
                                '',
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(employeeSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: employees.when(
              data: (list) => list.isEmpty
                  ? EmptyState(
                      message: 'Aucun employé trouvé',
                      icon: Icons.people_outline,
                      actionLabel: 'Ajouter un employé',
                      onAction: () => context.go('/employees/add'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _EmployeeTile(employee: list[i]),
                    ),
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/employees/add'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nouvel employé'),
      ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  final EmployeeModel employee;
  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: EmployeeAvatar(
          photoUrl: employee.photoUrl,
          name: employee.fullName,
          radius: 26,
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${employee.poste} • ${employee.departementNom} • ${employee.matricule}',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            StatusBadge(status: employee.statut),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _handleAction(context, ref, v),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Voir'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => context.go('/employees/${employee.id}'),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'view':
        context.go('/employees/${employee.id}');
      case 'edit':
        context.go('/employees/${employee.id}/edit');
      case 'delete':
        final confirm = await showConfirm(
          context,
          title: 'Supprimer l\'employé',
          message: 'Voulez-vous vraiment supprimer ${employee.fullName} ?',
        );
        if (confirm && context.mounted) {
          await ref
              .read(firestoreServiceProvider)
              .deleteEmployee(employee.id, employee.departementId);
          if (context.mounted) showSnack(context, 'Employé supprimé');
        }
    }
  }
}
