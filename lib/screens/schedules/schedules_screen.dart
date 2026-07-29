import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/schedule_model.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Horaires de travail')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel horaire'),
      ),
      body: schedules.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun horaire configuré'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              final color = s.type == 'nuit'
                  ? AppColors.primaryDark
                  : s.type == 'weekend'
                      ? AppColors.info
                      : s.type == 'rotation'
                          ? AppColors.warning
                          : AppColors.primary;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.schedule_outlined, color: color),
                  ),
                  title: Text(s.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.debut} → ${s.fin} • ${s.jours}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(s.type, style: TextStyle(color: color, fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        onPressed: () => _delete(context, ref, s.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(firestoreServiceProvider).deleteSchedule(id);
    showSnack(context, 'Horaire supprimé');
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    final nomCtrl = TextEditingController();
    final debutCtrl = TextEditingController(text: '08:00');
    final finCtrl = TextEditingController(text: '17:00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
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
                value: 'normal',
                items: ['normal', 'nuit', 'weekend', 'rotation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {},
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Jours',
                value: 'Lun-Ven',
                items: ['Lun-Ven', 'Lun-Sam', 'Sam-Dim', 'Tous les jours'].map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (v) {},
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nomCtrl.text.isNotEmpty) {
                    final service = ref.read(firestoreServiceProvider);
                    await service.addSchedule(ScheduleModel(
                      id: '',
                      nom: nomCtrl.text,
                      debut: debutCtrl.text,
                      fin: finCtrl.text,
                      jours: 'Lun-Ven',
                      type: 'normal',
                      createdAt: DateTime.now(),
                    ));
                    if (ctx.mounted) {
                      Navigator.pop(context);
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
    );
  }
}