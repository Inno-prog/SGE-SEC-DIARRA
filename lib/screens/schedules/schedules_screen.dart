import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/schedule_model.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(schedulesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Horaires de travail'),
        actions: [NotificationBell()],
      ),
      body: schedules.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((s) =>
                    s.nom.toLowerCase().contains(q) ||
                    s.type.toLowerCase().contains(q) ||
                    s.jours.toLowerCase().contains(q))
                .toList();
          }

          return _SchedulesPageContent(
            schedules: filtered,
            onAdd: () => _showForm(context, ref),
            search: _search,
            onSearch: (v) => setState(() => _search = v),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    final nomCtrl = TextEditingController();
    final debutCtrl = TextEditingController(text: '08:00');
    final finCtrl = TextEditingController(text: '17:00');
    String selectedType = 'normal';
    String selectedJours = 'Lun-Ven';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nouvel horaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  AppTextField(label: 'Nom de l\'horaire', controller: nomCtrl),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AppTextField(label: 'Heure début', controller: debutCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'Heure fin', controller: finCtrl)),
                  ]),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    label: 'Type',
                    value: selectedType,
                    items: ['normal', 'nuit', 'weekend', 'rotation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) {
                      if (v != null) selectedType = v;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    label: 'Jours',
                    value: selectedJours,
                    items: ['Lun-Ven', 'Lun-Sam', 'Sam-Dim', 'Tous les jours'].map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                    onChanged: (v) {
                      if (v != null) selectedJours = v;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (nomCtrl.text.isNotEmpty) {
                        final scheduleService = ref.read(scheduleApiServiceProvider);
                        await scheduleService.createSchedule(ScheduleModel(
                          id: '',
                          nom: nomCtrl.text,
                          debut: debutCtrl.text,
                          fin: finCtrl.text,
                          jours: selectedJours,
                          type: selectedType,
                          createdAt: DateTime.now(),
                        ));
                        if (ctx.mounted) {
                          ref.invalidate(schedulesProvider);
                          Navigator.pop(ctx);
                          showSnack(context, 'Horaire ajouté');
                        }
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _SchedulesPageContent extends ConsumerWidget {
  final List<ScheduleModel> schedules;
  final VoidCallback onAdd;
  final String search;
  final ValueChanged<String> onSearch;

  const _SchedulesPageContent({
    required this.schedules,
    required this.onAdd,
    required this.search,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build columns inside build method to have access to context and ref
    final columns = _buildColumns(context: context, ref: ref);

    if (schedules.isEmpty) {
      return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProPageHeader(
                icon: Icons.schedule_outlined,
                title: 'Horaires de travail',
                subtitle: 'Gestion des horaires et plannings',
                count: 0,
              ),
              const SizedBox(height: 16),
              ProListToolbar(
                searchHint: 'Rechercher un horaire...',
                onSearch: onSearch,
                addLabel: 'Nouvel horaire',
                onAdd: onAdd,
              ),
              const SizedBox(height: 16),
              const EmptyState(
                message: 'Aucun horaire configuré',
                icon: Icons.schedule_outlined,
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
              icon: Icons.schedule_outlined,
              title: 'Horaires de travail',
              subtitle: 'Gestion des horaires et plannings',
              count: schedules.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher un horaire...',
              onSearch: onSearch,
              addLabel: 'Nouvel horaire',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<ScheduleModel>(
              minWidth: 900,
              columns: columns,
              items: schedules,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<ScheduleModel>> _buildColumns({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return [
      ProColumn<ScheduleModel>(
        label: 'Nom',
        flex: 3,
        cell: (s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(s.type).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.schedule_outlined, size: 20, color: _getTypeColor(s.type)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                s.nom,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
      ProColumn<ScheduleModel>(
        label: 'Type',
        flex: 2,
        alignment: Alignment.center,
        cell: (s) => ProStatusChip(label: s.type, color: _getTypeColor(s.type)),
      ),
      ProColumn<ScheduleModel>(
        label: 'Heures',
        flex: 2,
        alignment: Alignment.center,
        cell: (s) => Text('${s.debut} → ${s.fin}'),
      ),
      ProColumn<ScheduleModel>(
        label: 'Jours',
        flex: 2,
        alignment: Alignment.center,
        cell: (s) => Text(s.jours),
      ),
      ProColumn<ScheduleModel>(
        label: 'Créé le',
        flex: 2,
        alignment: Alignment.center,
        cell: (s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}',
            ),
          ],
        ),
      ),
      ProColumn<ScheduleModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () => _delete(context, ref, s.id),
            ),
          ],
        ),
      ),
    ];
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'nuit':
        return AppColors.primaryDark;
      case 'weekend':
        return AppColors.info;
      case 'rotation':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(scheduleApiServiceProvider).deleteSchedule(id);
    if (context.mounted) showSnack(context, 'Horaire supprimé');
  }
}