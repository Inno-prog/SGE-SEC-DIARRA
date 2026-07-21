import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class LeavesScreen extends ConsumerStatefulWidget {
  const LeavesScreen({super.key});

  @override
  ConsumerState<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends ConsumerState<LeavesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    final isRH = user.role != AppConstants.roleEmployee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Congés'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Approuvés'),
            Tab(text: 'Refusés'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLeaveForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Demande de congé'),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LeaveList(statut: AppConstants.leavePending, isRH: isRH),
          _LeaveList(statut: AppConstants.leaveApproved, isRH: isRH),
          _LeaveList(statut: AppConstants.leaveRejected, isRH: isRH),
        ],
      ),
    );
  }

  void _showLeaveForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _LeaveForm(),
    );
  }
}

class _LeaveList extends ConsumerWidget {
  final String statut;
  final bool isRH;
  const _LeaveList({required this.statut, required this.isRH});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final leaves = ref.watch(leavesProvider(LeaveParams(employeeId: isRH ? null : user.employeeId, statut: statut)));

    return leaves.when(
      data: (list) => list.isEmpty
          ? const EmptyState(message: 'Aucune demande', icon: Icons.beach_access_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _LeaveTile(leave: list[i], isRH: isRH),
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _LeaveTile extends ConsumerWidget {
  final LeaveModel leave;
  final bool isRH;
  const _LeaveTile({required this.leave, required this.isRH});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmployeeAvatar(photoUrl: leave.employeePhoto, name: leave.employeeNom, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leave.employeeNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(leave.type, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                StatusBadge(status: leave.statut),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(leave.dateDebut)} → ${DateFormat('dd/MM/yyyy').format(leave.dateFin)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${leave.nombreJours}j', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (leave.motif.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(leave.motif, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
            if (isRH && leave.statut == AppConstants.leavePending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(context, ref, AppConstants.leaveRejected),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, ref, AppConstants.leaveApproved),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String statut) async {
    final user = ref.read(currentUserProvider)!;
    String? commentaire;
    if (statut == AppConstants.leaveRejected) {
      commentaire = await showDialog<String>(
        context: context,
        builder: (_) => _CommentDialog(title: 'Motif du refus'),
      );
      if (commentaire == null) return;
    }
    await ref.read(firestoreServiceProvider).updateLeaveStatus(leave.id, statut, user.fullName, commentaire);
    if (context.mounted) showSnack(context, statut == AppConstants.leaveApproved ? 'Congé approuvé' : 'Congé refusé');
  }
}

class _CommentDialog extends StatefulWidget {
  final String title;
  const _CommentDialog({required this.title});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Commentaire...'), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Confirmer')),
      ],
    );
  }
}

class _LeaveForm extends ConsumerStatefulWidget {
  const _LeaveForm();

  @override
  ConsumerState<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<_LeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  String? _employeePhoto;
  String _type = AppConstants.leaveAnnual;
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider)!;
    if (user.role == AppConstants.roleEmployee && user.employeeId != null) {
      _employeeId = user.employeeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final emp = ref.read(allEmployeesProvider).value?.firstWhere((e) => e.id == user.employeeId, orElse: () => throw Exception());
        if (emp != null) setState(() { _employeeNom = emp.fullName; _employeePhoto = emp.photoUrl; });
      });
    }
  }

  @override
  void dispose() { _motifCtrl.dispose(); super.dispose(); }

  int get _nombreJours => _dateFin.difference(_dateDebut).inDays + 1;

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : _dateFin,
      firstDate: DateTime.now(),
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
      await service.addLeave(LeaveModel(
        id: '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        employeePhoto: _employeePhoto,
        type: _type,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        nombreJours: _nombreJours,
        motif: _motifCtrl.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (mounted) { Navigator.pop(context); showSnack(context, 'Demande de congé soumise'); }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    final isRH = user.role != AppConstants.roleEmployee;
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
              const Text('Demande de congé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (isRH)
                employees.when(
                  data: (list) => AppDropdown<String>(
                    label: 'Employé *',
                    value: _employeeId,
                    items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                    onChanged: (v) {
                      final emp = list.firstWhere((e) => e.id == v);
                      setState(() { _employeeId = v; _employeeNom = emp.fullName; _employeePhoto = emp.photoUrl; });
                    },
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  loading: () => const SizedBox(),
                  error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
                ),
              if (isRH) const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Type de congé',
                value: _type,
                items: [AppConstants.leaveAnnual, AppConstants.leaveSick, AppConstants.leaveMaternity, AppConstants.leaveExceptional]
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
                    controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_dateFin)),
                    readOnly: true,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('Durée: $_nombreJours jour(s)', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Motif', controller: _motifCtrl, maxLines: 3, validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Soumettre la demande')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
