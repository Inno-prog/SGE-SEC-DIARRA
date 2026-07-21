import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final attendance = ref.watch(attendanceProvider(const AttendanceParams(employeeId: null)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Présences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showQRScanner(context, ref),
            tooltip: 'Scanner QR',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showManualForm(context, ref),
            tooltip: 'Pointage manuel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(selectedAttendanceDateProvider.notifier).state =
                      selectedDate.subtract(const Duration(days: 1)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
                      );
                      if (picked != null) ref.read(selectedAttendanceDateProvider.notifier).state = picked;
                    },
                    child: Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                      ? () => ref.read(selectedAttendanceDateProvider.notifier).state =
                          selectedDate.add(const Duration(days: 1))
                      : null,
                ),
              ],
            ),
          ),
          // Stats bar
          attendance.when(
            data: (list) => _AttendanceStats(list: list),
            loading: () => const SizedBox(),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error))),
          ),
          // List
          Expanded(
            child: attendance.when(
              data: (list) => list.isEmpty
                  ? const EmptyState(message: 'Aucun pointage pour cette date', icon: Icons.fingerprint)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _AttendanceTile(attendance: list[i]),
                    ),
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRScanner(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Scanner le QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.first;
                  if (barcode.rawValue != null) {
                    Navigator.pop(context);
                    _showManualForm(context, ref, employeeId: barcode.rawValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualForm(BuildContext context, WidgetRef ref, {String? employeeId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AttendanceForm(preselectedEmployeeId: employeeId),
    );
  }
}

class _AttendanceStats extends StatelessWidget {
  final List<AttendanceModel> list;
  const _AttendanceStats({required this.list});

  @override
  Widget build(BuildContext context) {
    final present = list.where((a) => a.statut == 'present').length;
    final absent = list.where((a) => a.statut == 'absent').length;
    final retard = list.where((a) => a.statut == 'retard').length;
    final conge = list.where((a) => a.statut == 'conge').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _StatChip('Présents', present, AppColors.success),
          const SizedBox(width: 8),
          _StatChip('Absents', absent, AppColors.error),
          const SizedBox(width: 8),
          _StatChip('Retards', retard, AppColors.warning),
          const SizedBox(width: 8),
          _StatChip('Congés', conge, AppColors.info),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends ConsumerWidget {
  final AttendanceModel attendance;
  const _AttendanceTile({required this.attendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: EmployeeAvatar(photoUrl: attendance.employeePhoto, name: attendance.employeeNom, radius: 22),
        title: Text(attendance.employeeNom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          attendance.heureArrivee != null
              ? '${DateFormat('HH:mm').format(attendance.heureArrivee!)}${attendance.heureDepart != null ? ' → ${DateFormat('HH:mm').format(attendance.heureDepart!)}' : ' (en cours)'}${attendance.retardMinutes > 0 ? ' • ${attendance.retardMinutes}min retard' : ''}'
              : '—',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(status: attendance.statut),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer ce pointage ?');
                  if (ok && context.mounted) {
                    await ref.read(firestoreServiceProvider).deleteAttendance(attendance.id);
                    if (context.mounted) showSnack(context, 'Pointage supprimé');
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceForm extends ConsumerStatefulWidget {
  final String? preselectedEmployeeId;
  const _AttendanceForm({this.preselectedEmployeeId});

  @override
  ConsumerState<_AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends ConsumerState<_AttendanceForm> {
  String? _employeeId;
  String? _employeeNom;
  String? _employeePhoto;
  String _statut = 'present';
  TimeOfDay _heureArrivee = TimeOfDay.now();
  TimeOfDay? _heureDepart;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployeeId != null) {
      _employeeId = widget.preselectedEmployeeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final emp = ref.read(allEmployeesProvider).value?.firstWhere(
          (e) => e.id == widget.preselectedEmployeeId,
          orElse: () => throw Exception(),
        );
        if (emp != null) setState(() { _employeeNom = emp.fullName; _employeePhoto = emp.photoUrl; });
      });
    }
  }

  Future<void> _pickTime(bool isArrivee) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isArrivee ? _heureArrivee : (_heureDepart ?? TimeOfDay.now()),
      builder: (_, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked != null) setState(() => isArrivee ? _heureArrivee = picked : _heureDepart = picked);
  }

  Future<void> _save() async {
    if (_employeeId == null) { showSnack(context, 'Sélectionnez un employé', isError: true); return; }
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider)!;
      final now = DateTime.now();
      final date = ref.read(selectedAttendanceDateProvider);
      final heureArrivee = DateTime(date.year, date.month, date.day, _heureArrivee.hour, _heureArrivee.minute);
      final heureDepart = _heureDepart != null ? DateTime(date.year, date.month, date.day, _heureDepart!.hour, _heureDepart!.minute) : null;

      await service.addAttendance(AttendanceModel(
        id: '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        employeePhoto: _employeePhoto,
        date: date,
        heureArrivee: heureArrivee,
        heureDepart: heureDepart,
        statut: _statut,
        methode: 'manuel',
        createdBy: user.id,
      ));
      if (mounted) { Navigator.pop(context); showSnack(context, 'Pointage enregistré'); }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pointage manuel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          employees.when(
            data: (list) => AppDropdown<String>(
              label: 'Employé *',
              value: _employeeId,
              items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
              onChanged: (v) {
                final emp = list.firstWhere((e) => e.id == v);
                setState(() { _employeeId = v; _employeeNom = emp.fullName; _employeePhoto = emp.photoUrl; });
              },
            ),
            loading: () => const SizedBox(),
            error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
          ),
          const SizedBox(height: 12),
          AppDropdown<String>(
            label: 'Statut',
            value: _statut,
            items: ['present', 'absent', 'retard', 'conge'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _statut = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Heure d\'arrivée', style: TextStyle(fontSize: 13)),
                subtitle: Text(_heureArrivee.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                onTap: () => _pickTime(true),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Heure de départ', style: TextStyle(fontSize: 13)),
                subtitle: Text(_heureDepart?.format(context) ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                onTap: () => _pickTime(false),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
