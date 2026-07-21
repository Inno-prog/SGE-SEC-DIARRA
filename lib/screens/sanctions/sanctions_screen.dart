import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

// ─── Sanctions ───────────────────────────────────────────────────────────────
class SanctionsScreen extends ConsumerWidget {
  const SanctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanctions = ref.watch(sanctionsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sanctions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle sanction'),
      ),
      body: sanctions.when(
        data: (list) => list.isEmpty
            ? const EmptyState(message: 'Aucune sanction', icon: Icons.gavel_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _SanctionTile(sanction: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [SanctionModel? s]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SanctionForm(sanction: s),
    );
  }
}

class _SanctionTile extends ConsumerWidget {
  final SanctionModel sanction;
  const _SanctionTile({required this.sanction});

  Color get _color {
    switch (sanction.type) {
      case AppConstants.sanctionWarning: return AppColors.warning;
      case AppConstants.sanctionBlame: return AppColors.accent;
      case AppConstants.sanctionSuspension: return AppColors.error;
      case AppConstants.sanctionLayoff: return AppColors.primaryDark;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.gavel_outlined, color: _color),
        ),
        title: Text(sanction.employeeNom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sanction.type, style: TextStyle(color: _color, fontWeight: FontWeight.w500, fontSize: 12)),
            Text(sanction.motif, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(sanction.date), style: const TextStyle(fontSize: 12)),
            if (sanction.dureeSuspension != null)
              Text('${sanction.dureeSuspension}j', style: const TextStyle(fontSize: 11, color: AppColors.error)),
          ],
        ),
        onLongPress: () async {
          final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer cette sanction ?');
          if (ok && context.mounted) {
            await ref.read(firestoreServiceProvider).deleteSanction(sanction.id);
            if (context.mounted) showSnack(context, 'Sanction supprimée');
          }
        },
      ),
    );
  }
}

class _SanctionForm extends ConsumerStatefulWidget {
  final SanctionModel? sanction;
  const _SanctionForm({this.sanction});

  @override
  ConsumerState<_SanctionForm> createState() => _SanctionFormState();
}

class _SanctionFormState extends ConsumerState<_SanctionForm> {
  final _formKey = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  String _type = AppConstants.sanctionWarning;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sanction != null) {
      _employeeId = widget.sanction!.employeeId;
      _employeeNom = widget.sanction!.employeeNom;
      _type = widget.sanction!.type;
      _motifCtrl.text = widget.sanction!.motif;
      _date = widget.sanction!.date;
      _dureeCtrl.text = widget.sanction!.dureeSuspension?.toString() ?? '';
    }
  }

  @override
  void dispose() { _motifCtrl.dispose(); _dureeCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _employeeId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final s = SanctionModel(
        id: widget.sanction?.id ?? '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        type: _type,
        motif: _motifCtrl.text.trim(),
        date: _date,
        dureeSuspension: int.tryParse(_dureeCtrl.text),
        decisionPar: user.fullName,
        createdAt: widget.sanction?.createdAt ?? DateTime.now(),
        createdBy: user.id,
      );
      if (widget.sanction != null) {
        await ref.read(firestoreServiceProvider).updateSanction(s);
      } else {
        await ref.read(firestoreServiceProvider).addSanction(s);
      }
      if (mounted) { Navigator.pop(context); showSnack(context, 'Sanction enregistrée'); }
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
            const Text('Nouvelle sanction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Employé *',
                value: _employeeId,
                items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                onChanged: (v) {
                  final emp = list.firstWhere((e) => e.id == v);
                  setState(() { _employeeId = v; _employeeNom = emp.fullName; });
                },
                validator: (v) => v == null ? 'Requis' : null,
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: 'Type de sanction',
              value: _type,
              items: [AppConstants.sanctionWarning, AppConstants.sanctionBlame, AppConstants.sanctionSuspension, AppConstants.sanctionLayoff]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Motif *', controller: _motifCtrl, maxLines: 3, validator: (v) => v!.isEmpty ? 'Requis' : null),
            if (_type == AppConstants.sanctionSuspension || _type == AppConstants.sanctionLayoff) ...[
              const SizedBox(height: 12),
              AppTextField(label: 'Durée (jours)', controller: _dureeCtrl, keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Trainings ───────────────────────────────────────────────────────────────
class TrainingsScreen extends ConsumerWidget {
  const TrainingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainings = ref.watch(trainingsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Formations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle formation'),
      ),
      body: trainings.when(
        data: (list) => list.isEmpty
            ? const EmptyState(message: 'Aucune formation', icon: Icons.school_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.school_outlined, color: AppColors.primary),
                      ),
                      title: Text(t.intitule, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${t.employeeNom} • ${t.organisme} • ${t.dureeJours}j'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(t.date), style: const TextStyle(fontSize: 12)),
                          if (t.attestationUrl != null)
                            const Icon(Icons.verified_outlined, color: AppColors.success, size: 16),
                        ],
                      ),
                      onLongPress: () async {
                        final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer cette formation ?');
                        if (ok && context.mounted) {
                          await ref.read(firestoreServiceProvider).deleteTraining(t.id);
                          if (context.mounted) showSnack(context, 'Formation supprimée');
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _TrainingForm(),
    );
  }
}

class _TrainingForm extends ConsumerStatefulWidget {
  const _TrainingForm();

  @override
  ConsumerState<_TrainingForm> createState() => _TrainingFormState();
}

class _TrainingFormState extends ConsumerState<_TrainingForm> {
  final _formKey = GlobalKey<FormState>();
  final _intituleCtrl = TextEditingController();
  final _organismeCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController(text: '1');
  String? _employeeId;
  String? _employeeNom;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() { _intituleCtrl.dispose(); _organismeCtrl.dispose(); _dureeCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _employeeId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      await ref.read(firestoreServiceProvider).addTraining(TrainingModel(
        id: '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        intitule: _intituleCtrl.text.trim(),
        date: _date,
        organisme: _organismeCtrl.text.trim(),
        dureeJours: int.tryParse(_dureeCtrl.text) ?? 1,
        createdAt: DateTime.now(),
        createdBy: user.id,
      ));
      if (mounted) { Navigator.pop(context); showSnack(context, 'Formation enregistrée'); }
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
            const Text('Nouvelle formation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Employé *',
                value: _employeeId,
                items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                onChanged: (v) {
                  final emp = list.firstWhere((e) => e.id == v);
                  setState(() { _employeeId = v; _employeeNom = emp.fullName; });
                },
                validator: (v) => v == null ? 'Requis' : null,
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Intitulé *', controller: _intituleCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppTextField(label: 'Organisme *', controller: _organismeCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Durée (jours)', controller: _dureeCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Date',
              controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_date)),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!));
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Evaluations ─────────────────────────────────────────────────────────────
class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evals = ref.watch(evaluationsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Évaluations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle évaluation'),
      ),
      body: evals.when(
        data: (list) => list.isEmpty
            ? const EmptyState(message: 'Aucune évaluation', icon: Icons.assessment_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.assessment_outlined, color: AppColors.primary),
                      ),
                      title: Text(e.employeeNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Année ${e.annee} • Par ${e.evaluateurNom}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${e.note}/20', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                          _NoteStars(note: e.note),
                        ],
                      ),
                      onLongPress: () async {
                        final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer cette évaluation ?');
                        if (ok && context.mounted) {
                          await ref.read(firestoreServiceProvider).deleteEvaluation(e.id);
                          if (context.mounted) showSnack(context, 'Évaluation supprimée');
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _EvaluationForm(),
    );
  }
}

class _NoteStars extends StatelessWidget {
  final double note;
  const _NoteStars({required this.note});

  @override
  Widget build(BuildContext context) {
    final stars = (note / 4).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 12, color: AppColors.gold)),
    );
  }
}

class _EvaluationForm extends ConsumerStatefulWidget {
  const _EvaluationForm();

  @override
  ConsumerState<_EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends ConsumerState<_EvaluationForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  double _note = 10;
  int _annee = DateTime.now().year;
  bool _loading = false;

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _employeeId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      await ref.read(firestoreServiceProvider).addEvaluation(EvaluationModel(
        id: '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        annee: _annee,
        note: _note,
        commentaire: _commentCtrl.text.trim(),
        evaluateurId: user.id,
        evaluateurNom: user.fullName,
        createdAt: DateTime.now(),
      ));
      if (mounted) { Navigator.pop(context); showSnack(context, 'Évaluation enregistrée'); }
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
            const Text('Nouvelle évaluation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Employé *',
                value: _employeeId,
                items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                onChanged: (v) {
                  final emp = list.firstWhere((e) => e.id == v);
                  setState(() { _employeeId = v; _employeeNom = emp.fullName; });
                },
                validator: (v) => v == null ? 'Requis' : null,
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Note: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_note.toStringAsFixed(1)}/20', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Slider(
              value: _note,
              min: 0,
              max: 20,
              divisions: 40,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _note = v),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Commentaire', controller: _commentCtrl, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
