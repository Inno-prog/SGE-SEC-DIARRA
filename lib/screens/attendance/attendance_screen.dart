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
    final attendance = ref.watch(
      attendanceProvider(
        AttendanceParams(date: selectedDate, employeeId: null),
      ),
    );
    final user = ref.watch(currentUserProvider);
    final canPoint = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Présences'),
        actions: [
          NotificationBell(),
          if (canPoint)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _showQRScanner(context, ref),
              tooltip: 'Scanner QR',
            ),
          if (canPoint)
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
                  onPressed: () =>
                      ref.read(selectedAttendanceDateProvider.notifier).state =
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
                        builder: (_, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null)
                        ref
                                .read(selectedAttendanceDateProvider.notifier)
                                .state =
                            picked;
                    },
                    child: Text(
                      DateFormat(
                        'EEEE d MMMM yyyy',
                        'fr_FR',
                      ).format(selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      selectedDate.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)),
                      )
                      ? () =>
                            ref
                                .read(selectedAttendanceDateProvider.notifier)
                                .state = selectedDate.add(
                              const Duration(days: 1),
                            )
                      : null,
                ),
              ],
            ),
          ),
          // Stats bar
          attendance.when(
            data: (list) {
              // Deduplicate by employeeId
              final seen = <String>{};
              final deduped = list.where((a) {
                if (seen.contains(a.employeeId)) return false;
                seen.add(a.employeeId);
                return true;
              }).toList();
              return _AttendanceStats(list: deduped);
            },
            loading: () => const SizedBox(),
            error: (e, _) => Center(
              child: Text(
                'Erreur: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          // List
          Expanded(
            child: attendance.when(
              data: (list) {
                // Deduplicate by employeeId - keep only the first entry per employee for this date
                final seen = <String>{};
                final deduped = list.where((a) {
                  if (seen.contains(a.employeeId)) return false;
                  seen.add(a.employeeId);
                  return true;
                }).toList();
                return deduped.isEmpty
                    ? const EmptyState(
                        message: 'Aucun pointage pour cette date',
                        icon: Icons.fingerprint,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: deduped.length,
                        itemBuilder: (_, i) =>
                            _AttendanceTile(attendance: deduped[i]),
                      );
              },
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
              child: Text(
                'Scanner le QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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

  void _showManualForm(
    BuildContext context,
    WidgetRef ref, {
    String? employeeId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

    return SizedBox(
      height: MediaQuery.of(context).size.width > 600 ? 100 : 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip('Présents', present, AppColors.success),
            _StatChip('Absents', absent, AppColors.error),
            _StatChip('Retards', retard, AppColors.warning),
            _StatChip('Congés', conge, AppColors.info),
          ],
        ),
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
    final w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: w > 600 ? 160 : 100,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: w > 600 ? 28 : 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: w > 600 ? 14 : 10)),
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
    final user = ref.watch(currentUserProvider);
    final canDelete = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: EmployeeAvatar(
          photoUrl: attendance.employeePhoto,
          name: attendance.employeeNom,
          radius: 22,
        ),
        title: Text(
          attendance.employeeNom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
            if (canDelete)
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    final ok = await showConfirm(
                      context,
                      title: 'Supprimer',
                      message: 'Supprimer ce pointage ?',
                    );
                    if (ok && context.mounted) {
                      await ref
                          .read(attendanceApiServiceProvider)
                          .deleteAttendance(attendance.id);
                      if (context.mounted) {
                        // Invalider le provider pour rafraîchir la liste
                        final selectedDate = ref.read(selectedAttendanceDateProvider);
                        ref.invalidate(attendanceProvider(AttendanceParams(date: selectedDate, employeeId: null)));
                        ref.invalidate(todayAttendanceProvider);
                        showSnack(context, 'Pointage supprimé');
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
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
  final _justificationCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployeeId != null) {
      _employeeId = widget.preselectedEmployeeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final emp = ref
            .read(allEmployeesProvider)
            .value
            ?.firstWhere(
              (e) => e.id == widget.preselectedEmployeeId,
              orElse: () => throw Exception(),
            );
        if (emp != null)
          setState(() {
            _employeeNom = emp.fullName;
            _employeePhoto = emp.photoUrl;
          });
      });
    }
    // Auto-fill times from normal schedule on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillFromNormalSchedule();
    });
  }

  @override
  void dispose() {
    _justificationCtrl.dispose();
    super.dispose();
  }

  void _autoFillFromNormalSchedule() {
    final schedules = ref.read(schedulesProvider);
    schedules.whenData((list) {
      final normalSchedule = list.where((s) => s.type == 'normal').firstOrNull;
      if (normalSchedule != null && mounted) {
        final debutParts = normalSchedule.debut.split(':');
        final finParts = normalSchedule.fin.split(':');
        if (debutParts.length >= 2 && finParts.length >= 2) {
          setState(() {
            _heureArrivee = TimeOfDay(
              hour: int.tryParse(debutParts[0]) ?? 8,
              minute: int.tryParse(debutParts[1]) ?? 0,
            );
            _heureDepart = TimeOfDay(
              hour: int.tryParse(finParts[0]) ?? 17,
              minute: int.tryParse(finParts[1]) ?? 0,
            );
          });
        }
      }
    });
  }

  Future<void> _pickTime(bool isArrivee) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isArrivee
          ? _heureArrivee
          : (_heureDepart ?? TimeOfDay.now()),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(
        () => isArrivee ? _heureArrivee = picked : _heureDepart = picked,
      );
  }

  Future<void> _save() async {
    if (_employeeId == null) {
      showSnack(context, 'Sélectionnez un employé', isError: true);
      return;
    }
    // Validate justification for absent status
    if (_statut == 'absent' && _justificationCtrl.text.trim().isEmpty) {
      showSnack(context, 'Le motif d\'absence est obligatoire', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final attendanceService = ref.read(attendanceApiServiceProvider);
      final user = ref.read(currentUserProvider)!;
      final date = ref.read(selectedAttendanceDateProvider);

      // For absent status, don't set arrival/departure times
      DateTime? heureArrivee;
      DateTime? heureDepart;
      if (_statut != 'absent') {
        heureArrivee = DateTime(
          date.year,
          date.month,
          date.day,
          _heureArrivee.hour,
          _heureArrivee.minute,
        );
        heureDepart = _heureDepart != null
            ? DateTime(
                date.year,
                date.month,
                date.day,
                _heureDepart!.hour,
                _heureDepart!.minute,
              )
            : null;
      }

      await attendanceService.createAttendance(
        AttendanceModel(
          id: '',
          employeeId: _employeeId!,
          employeeNom: _employeeNom!,
          employeePhoto: _employeePhoto,
          date: date,
          heureArrivee: heureArrivee,
          heureDepart: heureDepart,
          statut: _statut,
          justification: _statut == 'absent' ? _justificationCtrl.text.trim() : null,
          methode: 'manuel',
          createdBy: user.id,
        ),
      );
      if (mounted) {
        // Invalidation AVANT Navigator.pop
        // Invalider le provider pour la date sélectionnée (mêmes params que dans le build)
        ref.invalidate(todayAttendanceProvider);
        ref.invalidate(attendanceProvider(AttendanceParams(date: date, employeeId: null)));
        ref.invalidate(allAttendancesProvider); // Also invalidate for absences screen
        Navigator.pop(context);
        showSnack(context, 'Pointage enregistré');
      }
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pointage manuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Employé *',
                value: _employeeId,
                items: list
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  final emp = list.firstWhere((e) => e.id == v);
                  setState(() {
                    _employeeId = v;
                    _employeeNom = emp.fullName;
                    _employeePhoto = emp.photoUrl;
                  });
                },
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Center(
                child: Text(
                  "Erreur: $e",
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: 'Statut',
              value: _statut,
              items: [
                'present',
                'absent',
                'retard',
                'conge',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                setState(() {
                  _statut = v!;
                  // Auto-fill from normal schedule when 'present' is selected
                  if (_statut == 'present') {
                    _autoFillFromNormalSchedule();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (_statut != 'absent') ...[
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Heure d\'arrivée',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        _heureArrivee.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Heure de départ',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        _heureDepart?.format(context) ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ],
            if (_statut == 'absent') ...[
              AppTextField(
                label: 'Motif d\'absence *',
                controller: _justificationCtrl,
                maxLines: 3,
                hint: 'Raison de l\'absence...',
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: const Text('Enregistrer'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
