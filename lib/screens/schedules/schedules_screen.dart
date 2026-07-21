import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  final List<Map<String, dynamic>> _schedules = [
    {'nom': 'Horaire standard', 'debut': '08:00', 'fin': '17:00', 'jours': 'Lun-Ven', 'type': 'normal'},
    {'nom': 'Travail de nuit', 'debut': '22:00', 'fin': '06:00', 'jours': 'Lun-Ven', 'type': 'nuit'},
    {'nom': 'Week-end', 'debut': '08:00', 'fin': '14:00', 'jours': 'Sam-Dim', 'type': 'weekend'},
    {'nom': 'Rotation matin', 'debut': '06:00', 'fin': '14:00', 'jours': 'Lun-Ven', 'type': 'rotation'},
    {'nom': 'Rotation soir', 'debut': '14:00', 'fin': '22:00', 'jours': 'Lun-Ven', 'type': 'rotation'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Horaires de travail')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel horaire'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _schedules.length,
        itemBuilder: (_, i) {
          final s = _schedules[i];
          final color = s['type'] == 'nuit'
              ? AppColors.primaryDark
              : s['type'] == 'weekend'
                  ? AppColors.info
                  : s['type'] == 'rotation'
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
              title: Text(s['nom'], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s['debut']} → ${s['fin']} • ${s['jours']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(s['type'], style: TextStyle(color: color, fontSize: 11)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    onPressed: () => setState(() => _schedules.removeAt(i)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context) {
    final nomCtrl = TextEditingController();
    final debutCtrl = TextEditingController(text: '08:00');
    final finCtrl = TextEditingController(text: '17:00');
    String type = 'normal';
    String jours = 'Lun-Ven';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                value: type,
                items: ['normal', 'nuit', 'weekend', 'rotation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setModalState(() => type = v!),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Jours',
                value: jours,
                items: ['Lun-Ven', 'Lun-Sam', 'Sam-Dim', 'Tous les jours'].map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (v) => setModalState(() => jours = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nomCtrl.text.isNotEmpty) {
                    setState(() => _schedules.add({'nom': nomCtrl.text, 'debut': debutCtrl.text, 'fin': finCtrl.text, 'jours': jours, 'type': type}));
                    Navigator.pop(context);
                    showSnack(context, 'Horaire ajouté');
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
