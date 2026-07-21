import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contrats')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau contrat'),
      ),
      body: contracts.when(
        data: (list) {
          final expiring = list.where((c) => c.isExpiringSoon).toList();
          return Column(
            children: [
              if (expiring.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text('${expiring.length} contrat(s) expirent dans moins de 30 jours', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? EmptyState(message: 'Aucun contrat', icon: Icons.description_outlined, actionLabel: 'Ajouter', onAction: () => _showForm(context, ref))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _ContractTile(contract: list[i]),
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [ContractModel? contract]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ContractForm(contract: contract),
    );
  }
}

class _ContractTile extends ConsumerWidget {
  final ContractModel contract;
  const _ContractTile({required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: contract.isExpiringSoon ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.description_outlined, color: contract.isExpiringSoon ? AppColors.warning : AppColors.primary),
        ),
        title: Text(contract.employeeNom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contract.type, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
            Text(
              'Du ${DateFormat('dd/MM/yyyy').format(contract.dateDebut)}${contract.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(contract.dateFin!)}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            if (contract.isExpiringSoon)
              const Text('⚠️ Expire bientôt', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _ContractForm(contract: contract),
              );
            } else if (v == 'delete') {
              final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer ce contrat ?');
              if (ok && context.mounted) {
                await ref.read(firestoreServiceProvider).deleteContract(contract.id);
                if (context.mounted) showSnack(context, 'Contrat supprimé');
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
  }
}

class _ContractForm extends ConsumerStatefulWidget {
  final ContractModel? contract;
  const _ContractForm({this.contract});

  @override
  ConsumerState<_ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends ConsumerState<_ContractForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  String _type = AppConstants.contractCDI;
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _renouvellement = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _employeeId = widget.contract!.employeeId;
      _employeeNom = widget.contract!.employeeNom;
      _type = widget.contract!.type;
      _dateDebut = widget.contract!.dateDebut;
      _dateFin = widget.contract!.dateFin;
      _renouvellement = widget.contract!.renouvellement;
      _notesCtrl.text = widget.contract!.notes ?? '';
    }
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked != null) setState(() => isDebut ? _dateDebut = picked : _dateFin = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _employeeId == null) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider)!;
      final c = ContractModel(
        id: widget.contract?.id ?? '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        type: _type,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        renouvellement: _renouvellement,
        notes: _notesCtrl.text.trim(),
        createdAt: widget.contract?.createdAt ?? DateTime.now(),
        createdBy: user.id,
      );
      if (widget.contract != null) {
        await service.updateContract(c);
      } else {
        await service.addContract(c);
      }
      if (mounted) { Navigator.pop(context); showSnack(context, 'Contrat enregistré'); }
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.contract == null ? 'Nouveau contrat' : 'Modifier le contrat', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                label: 'Type de contrat',
                value: _type,
                items: [AppConstants.contractCDI, AppConstants.contractCDD, AppConstants.contractStage, AppConstants.contractConsultant, AppConstants.contractPrestataire]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    label: 'Date de début',
                    controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_dateDebut)),
                    readOnly: true,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Date de fin',
                    controller: TextEditingController(text: _dateFin != null ? DateFormat('dd/MM/yyyy').format(_dateFin!) : ''),
                    readOnly: true,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Renouvellement automatique'),
                value: _renouvellement,
                onChanged: (v) => setState(() => _renouvellement = v),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              AppTextField(label: 'Notes', controller: _notesCtrl, maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
