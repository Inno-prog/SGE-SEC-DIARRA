import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class AbsencesScreen extends ConsumerStatefulWidget {
  const AbsencesScreen({super.key});

  @override
  ConsumerState<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends ConsumerState<AbsencesScreen> {
  String _search = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(allAttendancesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Absences'),
        actions: [NotificationBell()],
      ),
      body: attendance.when(
        data: (list) {
          var absences = list.where((a) => a.statut == 'absent').toList();

          // Filtre recherche
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            absences = absences
                .where((a) =>
                    a.employeeNom.toLowerCase().contains(q) ||
                    a.methode.toLowerCase().contains(q) ||
                    (a.justification?.toLowerCase().contains(q) ?? false))
                .toList();
          }

          // Filtre date
          if (_dateRange != null) {
            absences = absences.where((a) {
              final d = DateTime(a.date.year, a.date.month, a.date.day);
              final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
              final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
              return !d.isBefore(start) && !d.isAfter(end);
            }).toList();
          }

          final user = ref.watch(currentUserProvider);
          final canAdd = user != null &&
              (user.role == AppConstants.roleAdmin ||
                  user.role == AppConstants.roleDirector ||
                  user.role == AppConstants.roleRH);

          return _AbsencesPageContent(
            absences: absences,
            search: _search,
            dateRange: _dateRange,
            canAdd: canAdd,
            onSearch: (v) => setState(() => _search = v),
            onDateFilter: (r) => setState(() => _dateRange = r),
            onAdd: () => _showAddDialog(context, ref),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter une absence'),
        content: const Text('Formulaire d\'ajout d\'absence à implémenter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

/// Page content using new Pro components
class _AbsencesPageContent extends ConsumerWidget {
  final List<AttendanceModel> absences;
  final String search;
  final DateTimeRange? dateRange;
  final bool canAdd;
  final ValueChanged<String> onSearch;
  final ValueChanged<DateTimeRange?> onDateFilter;
  final VoidCallback onAdd;

  const _AbsencesPageContent({
    required this.absences,
    required this.search,
    required this.dateRange,
    required this.canAdd,
    required this.onSearch,
    required this.onDateFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canDelete = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    // Build columns that need access to context/ref
    final columns = _buildColumns(
      canDelete: canDelete,
      context: context,
      ref: ref,
    );

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page Header
            ProPageHeader(
              icon: Icons.event_busy_outlined,
              title: 'Liste des absences',
              subtitle: 'Gestion et suivi des absences du personnel',
              count: absences.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher un employé...',
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
              addLabel: 'Ajouter une absence',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<AttendanceModel>(
              minWidth: 1100,
              columns: columns,
              items: absences,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<AttendanceModel>> _buildColumns({
    required bool canDelete,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return [
      ProColumn<AttendanceModel>(
        label: 'Employé',
        flex: 3,
        cell: (a) => ProEmployeeCell(
          name: a.employeeNom,
          subtitle: 'Employé',
        ),
      ),
      ProColumn<AttendanceModel>(
        label: 'Date',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(DateFormat('dd/MM/yyyy').format(a.date)),
          ],
        ),
      ),
      ProColumn<AttendanceModel>(
        label: 'Heure arrivée',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => a.heureArrivee == null
            ? const Text('—')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(DateFormat('HH:mm').format(a.heureArrivee!)),
                ],
              ),
      ),
      ProColumn<AttendanceModel>(
        label: 'Heure départ',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => a.heureDepart == null
            ? const Text('—')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(DateFormat('HH:mm').format(a.heureDepart!)),
                ],
              ),
      ),
      ProColumn<AttendanceModel>(
        label: 'Retard (min)',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => a.retardMinutes > 0
            ? ProStatusChip(label: '${a.retardMinutes} min', icon: Icons.schedule, color: AppColors.warning)
            : const Text('—'),
      ),
      ProColumn<AttendanceModel>(
        label: 'Justification',
        flex: 3,
        cell: (a) => a.justification == null || a.justification!.isEmpty
            ? const Text('—')
            : ProStatusChip(label: a.justification!, icon: Icons.add_circle, color: Colors.orange.shade800),
      ),
      ProColumn<AttendanceModel>(
        label: 'Méthode',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => ProStatusChip(label: a.methode, icon: Icons.laptop, color: AppColors.primary),
      ),
      ProColumn<AttendanceModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (a) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: Colors.blue.shade700,
              tooltip: 'Voir détails',
              onTap: () => _showDetails(context, a),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () {},
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
                    message: 'Supprimer cette absence ?',
                  );
                  if (ok && context.mounted) {
                    await ref.read(attendanceApiServiceProvider).deleteAttendance(a.id);
                    if (context.mounted) showSnack(context, 'Absence supprimée');
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ];
  }

  void _showDetails(BuildContext context, AttendanceModel a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Détails - ${a.employeeNom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Date', DateFormat('dd/MM/yyyy').format(a.date)),
            _DetailRow('Heure arrivée', a.heureArrivee != null ? DateFormat('HH:mm').format(a.heureArrivee!) : '—'),
            _DetailRow('Heure départ', a.heureDepart != null ? DateFormat('HH:mm').format(a.heureDepart!) : '—'),
            _DetailRow('Retard', a.retardMinutes > 0 ? '${a.retardMinutes} min' : '—'),
            _DetailRow('Statut', a.statut),
            _DetailRow('Méthode', a.methode),
            _DetailRow('Justification', a.justification ?? 'Aucune'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}