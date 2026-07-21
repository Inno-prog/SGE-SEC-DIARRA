import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/department_model.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depts = ref.watch(departmentsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Départements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau département'),
      ),
      body: depts.when(
        data: (list) => list.isEmpty
            ? EmptyState(message: 'Aucun département', icon: Icons.business_outlined, actionLabel: 'Ajouter', onAction: () => _showForm(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _DeptCard(dept: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [DepartmentModel? dept]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DeptForm(dept: dept),
    );
  }
}

class _DeptCard extends ConsumerWidget {
  final DepartmentModel dept;
  const _DeptCard({required this.dept});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.business_outlined, color: AppColors.primary),
        ),
        title: Text(dept.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dept.description != null) Text(dept.description!, style: const TextStyle(fontSize: 12)),
            Text('${dept.nombreEmployes} employé(s)${dept.responsableNom != null ? ' • Resp: ${dept.responsableNom}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _DeptForm(dept: dept),
              );
            } else if (v == 'delete') {
              final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer le département "${dept.nom}" ?');
              if (ok && context.mounted) {
                await ref.read(firestoreServiceProvider).deleteDepartment(dept.id);
                if (context.mounted) showSnack(context, 'Département supprimé');
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppColors.error))])),
          ],
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
      final service = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider)!;
      if (widget.dept != null) {
        await service.updateDepartment(widget.dept!.copyWith(nom: _nomCtrl.text.trim(), description: _descCtrl.text.trim(), responsableId: _responsableId, responsableNom: _responsableNom));
        await service.addAuditLog(userId: user.id, userNom: user.fullName, action: 'modification', collection: AppConstants.colDepartments, documentId: widget.dept!.id, description: 'Modification département ${_nomCtrl.text}');
      } else {
        final id = await service.addDepartment(DepartmentModel(id: '', nom: _nomCtrl.text.trim(), description: _descCtrl.text.trim(), responsableId: _responsableId, responsableNom: _responsableNom, createdAt: DateTime.now()));
        await service.addAuditLog(userId: user.id, userNom: user.fullName, action: 'ajout', collection: AppConstants.colDepartments, documentId: id, description: 'Ajout département ${_nomCtrl.text}');
      }
      if (mounted) { Navigator.pop(context); showSnack(context, 'Département enregistré'); }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(allEmployeesProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.dept == null ? 'Nouveau département' : 'Modifier le département', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AppTextField(label: 'Nom *', controller: _nomCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Description', controller: _descCtrl, maxLines: 2),
            const SizedBox(height: 12),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Responsable',
                value: _responsableId,
                items: [const DropdownMenuItem(value: null, child: Text('Aucun')), ...list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))],
                onChanged: (v) {
                  final emp = v != null ? list.firstWhere((e) => e.id == v) : null;
                  setState(() { _responsableId = v; _responsableNom = emp?.fullName; });
                },
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enregistrer'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
