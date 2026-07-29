import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class RecruitmentScreen extends ConsumerWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(recruitmentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recrutement')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle offre'),
      ),
      body: offers.when(
        data: (list) => list.isEmpty
            ? const EmptyState(message: 'Aucune offre de recrutement', icon: Icons.person_search_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _OfferCard(offer: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [RecruitmentModel? offer]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecruitmentForm(offer: offer),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final RecruitmentModel offer;
  const _OfferCard({required this.offer});

  Color get _statusColor {
    switch (offer.statut) {
      case 'ouvert': return AppColors.success;
      case 'ferme': return AppColors.error;
      case 'pourvu': return AppColors.info;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.poste, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(offer.departementNom, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(offer.statut, style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(offer.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(Icons.work_outline, offer.typeContrat),
                const SizedBox(width: 8),
                _InfoChip(Icons.people_outline, '${offer.nombreCandidatures} candidature(s)'),
                const Spacer(),
                if (offer.dateLimite != null)
                  Text('Limite: ${DateFormat('dd/MM/yyyy').format(offer.dateLimite!)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _changeStatus(context, ref),
                    child: const Text('Changer statut'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () async {
                    final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer cette offre ?');
                    if (ok) {
                      try {
                        await ref.read(firestoreServiceProvider).deleteRecruitment(offer.id);
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Changer le statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['ouvert', 'ferme', 'pourvu'].map((s) => ListTile(
              title: Text(s),
              onTap: () async {
                try {
                  final updated = RecruitmentModel(
                    id: offer.id,
                    poste: offer.poste,
                    departementId: offer.departementId,
                    departementNom: offer.departementNom,
                    description: offer.description,
                    typeContrat: offer.typeContrat,
                    datePublication: offer.datePublication,
                    dateLimite: offer.dateLimite,
                    statut: s,
                    nombreCandidatures: offer.nombreCandidatures,
                    createdBy: offer.createdBy,
                    createdAt: offer.createdAt,
                  );
                  await ref.read(firestoreServiceProvider).updateRecruitment(updated);
                } catch (_) {}
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(s == 'ferme' ? 'Offre fermée' : s == 'pourvu' ? 'Offre pourvue' : 'Offre rouverte'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            )).toList(),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RecruitmentForm extends ConsumerStatefulWidget {
  final RecruitmentModel? offer;
  const _RecruitmentForm({this.offer});

  @override
  ConsumerState<_RecruitmentForm> createState() => _RecruitmentFormState();
}

class _RecruitmentFormState extends ConsumerState<_RecruitmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _posteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _deptId;
  String? _deptNom;
  String _typeContrat = AppConstants.contractCDI;
  DateTime? _dateLimite;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.offer != null) {
      _posteCtrl.text = widget.offer!.poste;
      _descCtrl.text = widget.offer!.description;
      _deptId = widget.offer!.departementId;
      _deptNom = widget.offer!.departementNom;
      _typeContrat = widget.offer!.typeContrat;
      _dateLimite = widget.offer!.dateLimite;
    }
  }

  @override
  void dispose() { _posteCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _deptId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final r = RecruitmentModel(
        id: widget.offer?.id ?? '',
        poste: _posteCtrl.text.trim(),
        departementId: _deptId!,
        departementNom: _deptNom!,
        description: _descCtrl.text.trim(),
        typeContrat: _typeContrat,
        datePublication: widget.offer?.datePublication ?? DateTime.now(),
        dateLimite: _dateLimite,
        statut: widget.offer?.statut ?? 'ouvert',
        nombreCandidatures: widget.offer?.nombreCandidatures ?? 0,
        createdBy: user.id,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
      );
      if (widget.offer != null) {
        await ref.read(firestoreServiceProvider).updateRecruitment(r);
      } else {
        await ref.read(firestoreServiceProvider).addRecruitment(r);
      }
      if (mounted) { Navigator.pop(context); showSnack(context, 'Offre enregistrée'); }
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nouvelle offre de recrutement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              AppTextField(label: 'Poste *', controller: _posteCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              depts.when(
                data: (list) => AppDropdown<String>(
                  label: 'Département *',
                  value: _deptId,
                  items: list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nom))).toList(),
                  onChanged: (v) {
                    final d = list.firstWhere((d) => d.id == v);
                    setState(() { _deptId = v; _deptNom = d.nom; });
                  },
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                loading: () => const SizedBox(),
                error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Type de contrat',
                value: _typeContrat,
                items: [AppConstants.contractCDI, AppConstants.contractCDD, AppConstants.contractStage, AppConstants.contractConsultant, AppConstants.contractPrestataire]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _typeContrat = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Description *', controller: _descCtrl, maxLines: 4, validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Date limite',
                controller: TextEditingController(text: _dateLimite != null ? DateFormat('dd/MM/yyyy').format(_dateLimite!) : ''),
                readOnly: true,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateLimite ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
                  );
                  if (picked != null) setState(() => _dateLimite = picked);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Publier l\'offre')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
