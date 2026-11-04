import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class BonusesScreen extends ConsumerStatefulWidget {
  const BonusesScreen({super.key});

  @override
  ConsumerState<BonusesScreen> createState() => _BonusesScreenState();
}

class _BonusesScreenState extends ConsumerState<BonusesScreen> {
  String _search = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final bonusesAsync = ref.watch(allBonusesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Primes'),
        actions: [NotificationBell()],
      ),
      body: bonusesAsync.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((b) =>
                    b.employeeNom.toLowerCase().contains(q) ||
                    b.type.toLowerCase().contains(q) ||
                    b.motif.toLowerCase().contains(q))
                .toList();
          }
          if (_dateRange != null) {
            filtered = filtered.where((b) {
              final d = DateTime(b.dateAttribution.year, b.dateAttribution.month, b.dateAttribution.day);
              final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
              final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
              return !d.isBefore(start) && !d.isAfter(end);
            }).toList();
          }

          return _BonusesPageContent(
            bonuses: filtered,
            search: _search,
            dateRange: _dateRange,
            onSearch: (v) => setState(() => _search = v),
            onDateFilter: (r) => setState(() => _dateRange = r),
            onAdd: () => _showForm(context, ref),
            onDelete: (b) async {
              final ok = await showConfirm(
                context,
                title: 'Supprimer la prime',
                message: 'Supprimer cette prime ?',
              );
              if (ok && context.mounted) {
                await ref.read(bonusApiServiceProvider).deleteBonus(b.id);
                ref.invalidate(allBonusesProvider);
                if (context.mounted) showSnack(context, 'Prime supprimée');
              }
            },
            onView: (b) => _showViewDialog(context, b),
            onEdit: (b) => _showEditForm(context, ref, b),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    final montantCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String? employeeId;
    String? employeeNom;
    String selectedType = 'Prime de rendement';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              final employees = ref.watch(allEmployeesProvider);
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Attribuer une prime',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      employees.when(
                        data: (list) => AppDropdown<String>(
                          label: 'Employé *',
                          value: employeeId,
                          items: list
                              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                              .toList(),
                          onChanged: (v) {
                            final emp = list.firstWhere((e) => e.id == v);
                            setModalState(() {
                              employeeId = v;
                              employeeNom = emp.fullName;
                            });
                          },
                        ),
                        loading: () => const SizedBox(),
                        error: (e, _) => Text('Erreur: $e'),
                      ),
                      const SizedBox(height: 12),
                      AppDropdown<String>(
                        label: 'Type de prime',
                        value: selectedType,
                        items: ['Prime de rendement', 'Prime de risque', 'Prime exceptionnelle', 'Prime d\'ancienneté']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setModalState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Montant (FCFA) *',
                        controller: montantCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(label: 'Motif', controller: motifCtrl, maxLines: 2),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (employeeId == null || montantCtrl.text.isEmpty) {
                            showSnack(context, 'Remplissez tous les champs requis', isError: true);
                            return;
                          }
                          context.pop();
                          final user = ref.read(currentUserProvider);
                          await ref.read(bonusApiServiceProvider).createBonus(
                            BonusModel(
                              id: '',
                              employeeId: employeeId!,
                              employeeNom: employeeNom ?? '',
                              type: selectedType,
                              montant: double.tryParse(montantCtrl.text) ?? 0,
                              motif: motifCtrl.text,
                              dateAttribution: DateTime.now(),
                              statut: 'active',
                              createdAt: DateTime.now(),
                              createdBy: user?.id ?? '',
                            ),
                          );
                          ref.invalidate(allBonusesProvider);
                          if (context.mounted) {
                            showSnack(context,
                                'Prime de ${NumberFormat('#,###').format(double.tryParse(montantCtrl.text) ?? 0)} FCFA attribuée à $employeeNom');
                          }
                        },
                        child: const Text('Attribuer la prime'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showViewDialog(BuildContext context, BonusModel bonus) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Détails de la prime',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDetailRow('Employé', bonus.employeeNom),
                _buildDetailRow('Type', bonus.type),
                _buildDetailRow('Montant', '${NumberFormat('#,###').format(bonus.montant)} FCFA'),
                _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(bonus.dateAttribution)),
                _buildDetailRow('Motif', bonus.motif.isEmpty ? '—' : bonus.motif),
                _buildDetailRow('Statut', bonus.statut),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context, WidgetRef ref, BonusModel bonus) {
    final montantCtrl = TextEditingController(text: bonus.montant.toString());
    final motifCtrl = TextEditingController(text: bonus.motif);
    String selectedType = bonus.type;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20, right: 20, top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Modifier la prime',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      AppDropdown<String>(
                        label: 'Type de prime',
                        value: selectedType,
                        items: ['Prime de rendement', 'Prime de risque', 'Prime exceptionnelle', 'Prime d\'ancienneté']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setModalState(() => selectedType = v!),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Montant (FCFA) *',
                        controller: montantCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(label: 'Motif', controller: motifCtrl, maxLines: 2),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (montantCtrl.text.isEmpty) {
                            showSnack(context, 'Remplissez tous les champs requis', isError: true);
                            return;
                          }
                          context.pop();
                          await ref.read(bonusApiServiceProvider).updateBonus(
                            bonus.id,
                            BonusModel(
                              id: bonus.id,
                              employeeId: bonus.employeeId,
                              employeeNom: bonus.employeeNom,
                              type: selectedType,
                              montant: double.tryParse(montantCtrl.text) ?? 0,
                              motif: motifCtrl.text,
                              dateAttribution: bonus.dateAttribution,
                              statut: bonus.statut,
                              createdAt: bonus.createdAt,
                              createdBy: bonus.createdBy,
                            ),
                          );
                          ref.invalidate(allBonusesProvider);
                          if (context.mounted) {
                            showSnack(context, 'Prime modifiée avec succès');
                          }
                        },
                        child: const Text('Enregistrer les modifications'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _BonusesPageContent extends ConsumerWidget {
  final List<BonusModel> bonuses;
  final String search;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSearch;
  final ValueChanged<DateTimeRange?> onDateFilter;
  final VoidCallback onAdd;
  final void Function(BonusModel) onDelete;
  final void Function(BonusModel) onView;
  final void Function(BonusModel) onEdit;

  const _BonusesPageContent({
    required this.bonuses,
    required this.search,
    required this.dateRange,
    required this.onSearch,
    required this.onDateFilter,
    required this.onAdd,
    required this.onDelete,
    required this.onView,
    required this.onEdit,
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
              icon: Icons.star_outline,
              title: 'Liste des primes',
              subtitle: 'Gestion et attribution des primes du personnel',
              count: bonuses.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher un employé, type de prime...',
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
              addLabel: 'Nouvelle prime',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<BonusModel>(
              minWidth: 1100,
              columns: _buildColumns(),
              items: bonuses,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<BonusModel>> _buildColumns() {
    return [
      ProColumn<BonusModel>(
        label: 'Employé',
        flex: 1,
        cell: (b) => ProEmployeeCell(
          name: b.employeeNom,
          subtitle: 'Employé',
        ),
      ),
      ProColumn<BonusModel>(
        label: 'Type',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => ProStatusChip(label: b.type, color: AppColors.primary),
      ),
      ProColumn<BonusModel>(
        label: 'Montant',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => Text('${NumberFormat('#,###').format(b.montant)} FCFA'),
      ),
      ProColumn<BonusModel>(
        label: 'Date',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(DateFormat('dd/MM/yyyy').format(b.dateAttribution)),
          ],
        ),
      ),
      ProColumn<BonusModel>(
        label: 'Motif',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => Text(
          b.motif.isEmpty ? '—' : b.motif,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      ProColumn<BonusModel>(
        label: 'Statut',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => ProStatusChip(
          label: b.statut,
          color: b.statut == 'active' ? AppColors.success : Colors.grey,
        ),
      ),
      ProColumn<BonusModel>(
        label: 'Actions',
        flex: 1,
        alignment: Alignment.center,
        cell: (b) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: Colors.blue.shade700,
              tooltip: 'Voir',
              onTap: () => onView(b),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () => onEdit(b),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () => onDelete(b),
            ),
          ],
        ),
      ),
    ];
  }
}