import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/department_model.dart';

class PositionsScreen extends ConsumerWidget {
  const PositionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(positionsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Postes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau poste'),
      ),
      body: positions.when(
        data: (list) => list.isEmpty
            ? EmptyState(message: 'Aucun poste', icon: Icons.work_outline, actionLabel: 'Ajouter', onAction: () => _showForm(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.work_outline, color: AppColors.primary),
                      ),
                      title: Text(p.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(p.departementNom ?? '—'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') _showForm(context, ref, p);
                          if (v == 'delete') {
                            final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer le poste "${p.titre}" ?');
                            if (ok && context.mounted) {
                              await ref.read(firestoreServiceProvider).deletePosition(p.id);
                              if (context.mounted) showSnack(context, 'Poste supprimé');
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [dynamic pos]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PositionForm(position: pos),
    );
  }
}

class _PositionForm extends ConsumerStatefulWidget {
  final dynamic position;
  const _PositionForm({this.position});

  @override
  ConsumerState<_PositionForm> createState() => _PositionFormState();
}

class _PositionFormState extends ConsumerState<_PositionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _miniCtrl = TextEditingController();
  final _maxiCtrl = TextEditingController();
  String? _deptId;
  String? _deptNom;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.position != null) {
      _titreCtrl.text = widget.position.titre;
      _descCtrl.text = widget.position.description ?? '';
      _deptId = widget.position.departementId;
      _deptNom = widget.position.departementNom;
      _miniCtrl.text = widget.position.salaireMini?.toString() ?? '';
      _maxiCtrl.text = widget.position.salaireMaxi?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose(); _descCtrl.dispose(); _miniCtrl.dispose(); _maxiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final pos = PositionModel(
        id: widget.position?.id ?? '',
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        departementId: _deptId,
        departementNom: _deptNom,
        salaireMini: double.tryParse(_miniCtrl.text),
        salaireMaxi: double.tryParse(_maxiCtrl.text),
        createdAt: widget.position?.createdAt ?? DateTime.now(),
      );
      if (widget.position != null) {
        await service.updatePosition(pos);
      } else {
        await service.addPosition(pos);
      }
      if (mounted) { Navigator.pop(context); showSnack(context, 'Poste enregistré'); }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depts = ref.watch(departmentsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.position == null ? 'Nouveau poste' : 'Modifier le poste', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AppTextField(label: 'Titre *', controller: _titreCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            depts.when(
              data: (list) => AppDropdown<String>(
                label: 'Département',
                value: _deptId,
                items: [const DropdownMenuItem(value: null, child: Text('Aucun')), ...list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nom)))],
                onChanged: (v) {
                  final d = v != null ? list.firstWhere((d) => d.id == v) : null;
                  setState(() { _deptId = v; _deptNom = d?.nom; });
                },
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppTextField(label: 'Salaire min', controller: _miniCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Salaire max', controller: _maxiCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
