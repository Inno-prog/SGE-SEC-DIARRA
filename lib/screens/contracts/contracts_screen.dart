import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'contract_form.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  String _search = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractsProvider(null));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Contrats'),
        actions: [NotificationBell()],
      ),
      body: contractsAsync.when(
        data: (list) {
          var filtered = List<ContractModel>.from(list)
            ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((c) =>
                    c.employeeNom.toLowerCase().contains(q) ||
                    c.type.toLowerCase().contains(q) ||
                    c.statut.toLowerCase().contains(q))
                .toList();
          }
          if (_dateRange != null) {
            filtered = filtered.where((c) {
              final d = DateTime(c.dateDebut.year, c.dateDebut.month, c.dateDebut.day);
              final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
              final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
              return !d.isBefore(start) && !d.isAfter(end);
            }).toList();
          }

          final expiring = filtered.where((c) => c.isExpiringSoon).toList();

          return _ContractsPageContent(
            contracts: filtered,
            expiringContracts: expiring,
            search: _search,
            dateRange: _dateRange,
            onSearch: (v) => setState(() => _search = v),
            onDateFilter: (r) => setState(() => _dateRange = r),
            onAdd: () => _showForm(context, ref),
            onView: (c) => context.go('/contracts/${c.id}'),
            onEdit: (c) => _showForm(context, ref, c),
            onDelete: (c) async {
              final ok = await showConfirm(
                context,
                title: 'Supprimer le contrat',
                message: 'Voulez-vous vraiment supprimer ce contrat ?',
              );
              if (ok && context.mounted) {
                await ref.read(contractApiServiceProvider).deleteContract(c.id);
                if (context.mounted) showSnack(context, 'Contrat supprimé');
              }
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [ContractModel? contract]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ContractForm(contract: contract),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _ContractsPageContent extends ConsumerWidget {
  final List<ContractModel> contracts;
  final List<ContractModel> expiringContracts;
  final String search;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSearch;
  final ValueChanged<DateTimeRange?> onDateFilter;
  final VoidCallback onAdd;
  final void Function(ContractModel) onView;
  final void Function(ContractModel) onEdit;
  final void Function(ContractModel) onDelete;

  const _ContractsPageContent({
    required this.contracts,
    required this.expiringContracts,
    required this.search,
    required this.dateRange,
    required this.onSearch,
    required this.onDateFilter,
    required this.onAdd,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Expiring contracts alert
            if (expiringContracts.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      '${expiringContracts.length} contrat(s) expirent dans moins de 30 jours',
                      style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            // Page Header
            ProPageHeader(
              icon: Icons.assignment_outlined,
              title: 'Liste des contrats',
              subtitle: 'Gestion des contrats du personnel',
              count: contracts.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher par employé, type, statut...',
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
              addLabel: 'Nouveau contrat',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<ContractModel>(
              minWidth: 1100,
              columns: _buildColumns(),
              items: contracts,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<ContractModel>> _buildColumns() {
    return [
      ProColumn<ContractModel>(
        label: 'Employé',
        flex: 3,
        cell: (c) => ProEmployeeCell(
          name: c.employeeNom,
          subtitle: 'Employé',
        ),
      ),
      ProColumn<ContractModel>(
        label: 'Type',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => ProStatusChip(label: c.type, color: AppColors.primary),
      ),
      ProColumn<ContractModel>(
        label: 'Date début',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('${c.dateDebut.day.toString().padLeft(2, '0')}/${c.dateDebut.month.toString().padLeft(2, '0')}/${c.dateDebut.year}'),
          ],
        ),
      ),
      ProColumn<ContractModel>(
        label: 'Date fin',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => c.dateFin == null
            ? const Text('—')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('${c.dateFin!.day.toString().padLeft(2, '0')}/${c.dateFin!.month.toString().padLeft(2, '0')}/${c.dateFin!.year}'),
                ],
              ),
      ),
      ProColumn<ContractModel>(
        label: 'Durée (mois)',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => Text(c.dureeEnMois?.toString() ?? '—'),
      ),
      ProColumn<ContractModel>(
        label: 'Renouvellement',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => ProStatusChip(
          label: c.renouvellement ? 'Oui' : 'Non',
          color: c.renouvellement ? AppColors.success : Colors.grey,
        ),
      ),
      ProColumn<ContractModel>(
        label: 'Pièces jointes',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => Text('${c.piecesJointes.length}'),
      ),
      ProColumn<ContractModel>(
        label: 'Statut',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => _buildStatusChip(c.statut),
      ),
      ProColumn<ContractModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: Colors.blue.shade700,
              tooltip: 'Voir',
              onTap: () => onView(c),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () => onEdit(c),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () => onDelete(c),
            ),
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
      case 'expiré':
      case 'expire':
        color = AppColors.error;
        break;
      case 'brouillon':
        color = Colors.grey;
        break;
      case 'en cours':
        color = AppColors.info;
        break;
      default:
        color = Colors.grey;
    }
    return ProStatusChip(label: status, color: color);
  }
}