import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

// ─── Absences ────────────────────────────────────────────────────────────────
class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider(const AttendanceParams()));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Absences')),
      body: attendance.when(
        data: (list) {
          final absences = list.where((a) => a.statut == 'absent').toList();
          return absences.isEmpty
              ? const EmptyState(
                  message: 'Aucune absence enregistrée',
                  icon: Icons.event_busy_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: absences.length,
                  itemBuilder: (_, i) {
                    final a = absences[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: EmployeeAvatar(
                          photoUrl: a.employeePhoto,
                          name: a.employeeNom,
                          radius: 22,
                        ),
                        title: Text(
                          a.employeeNom,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(a.date)),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(status: a.statut),
                            if (a.justification != null)
                              const Text(
                                'Justifiée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                ),
                              )
                            else
                              const Text(
                                'Non justifiée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

// ─── Payroll ─────────────────────────────────────────────────────────────────
class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final payroll = ref.watch(
      payrollProvider(
        PayrollParams(mois: _mois, annee: _annee, employeeId: null),
      ),
    );
    final months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion de la paie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPayrollForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    if (_mois == 1) {
                      _mois = 12;
                      _annee--;
                    } else {
                      _mois--;
                    }
                  }),
                ),
                Expanded(
                  child: Text(
                    '${months[_mois]} $_annee',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    if (_mois == 12) {
                      _mois = 1;
                      _annee++;
                    } else {
                      _mois++;
                    }
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: payroll.when(
              data: (list) {
                if (list.isEmpty)
                  return EmptyState(
                    message:
                        'Aucune fiche de paie pour ${months[_mois]} $_annee',
                    icon: Icons.payments_outlined,
                    actionLabel: 'Générer',
                    onAction: () => _showPayrollForm(context),
                  );
                final totalNet = list.fold<double>(
                  0,
                  (s, p) => s + p.netAPayer,
                );
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total masse salariale',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(totalNet)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${list.length} fiches',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _PayrollTile(payroll: list[i]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Text(
                  'Erreur: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayrollForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PayrollForm(mois: _mois, annee: _annee),
    );
  }
}

class _PayrollTile extends ConsumerWidget {
  final PayrollModel payroll;
  const _PayrollTile({required this.payroll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
        title: Text(
          payroll.employeeNom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Brut: ${NumberFormat('#,###').format(payroll.brutTotal)} FCFA',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,###').format(payroll.netAPayer)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
            StatusBadge(status: payroll.statut),
          ],
        ),
        onTap: () => _showDetail(context, ref),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Fiche de paie — ${payroll.employeeNom}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PayRow('Salaire de base', payroll.salaireBase),
              _PayRow('Primes', payroll.primes),
              _PayRow('Bonus', payroll.bonus),
              _PayRow(
                'Heures supp.',
                payroll.heuresSupp * payroll.tauxHeureSupp,
              ),
              const Divider(),
              _PayRow('Brut total', payroll.brutTotal, bold: true),
              const Divider(),
              _PayRow(
                'Cotisations sociales',
                -payroll.cotisationsSociales,
                isDeduction: true,
              ),
              _PayRow('Impôts', -payroll.impots, isDeduction: true),
              _PayRow('Retenues', -payroll.retenues, isDeduction: true),
              const Divider(),
              _PayRow(
                'NET À PAYER',
                payroll.netAPayer,
                bold: true,
                color: AppColors.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showSnack(ctx, 'Génération PDF en cours...');
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool isDeduction;
  final Color? color;
  const _PayRow(
    this.label,
    this.value, {
    this.bold = false,
    this.isDeduction = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDeduction ? AppColors.error : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: c,
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(value)} FCFA',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollForm extends ConsumerStatefulWidget {
  final int mois;
  final int annee;
  const _PayrollForm({required this.mois, required this.annee});

  @override
  ConsumerState<_PayrollForm> createState() => _PayrollFormState();
}

class _PayrollFormState extends ConsumerState<_PayrollForm> {
  final _primesCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();
  final _heureSuppCtrl = TextEditingController();
  final _tauxCtrl = TextEditingController();
  final _retenuesCtrl = TextEditingController();
  final _cotisCtrl = TextEditingController();
  final _impotsCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  double _salaireBase = 0;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _primesCtrl,
      _bonusCtrl,
      _heureSuppCtrl,
      _tauxCtrl,
      _retenuesCtrl,
      _cotisCtrl,
      _impotsCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  double get _net {
    final brut =
        _salaireBase +
        (double.tryParse(_primesCtrl.text) ?? 0) +
        (double.tryParse(_bonusCtrl.text) ?? 0) +
        ((double.tryParse(_heureSuppCtrl.text) ?? 0) *
            (double.tryParse(_tauxCtrl.text) ?? 0));
    final deductions =
        (double.tryParse(_cotisCtrl.text) ?? 0) +
        (double.tryParse(_impotsCtrl.text) ?? 0) +
        (double.tryParse(_retenuesCtrl.text) ?? 0);
    return brut - deductions;
  }

  Future<void> _save() async {
    if (_employeeId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      await ref
          .read(firestoreServiceProvider)
          .addPayroll(
            PayrollModel(
              id: '',
              employeeId: _employeeId!,
              employeeNom: _employeeNom!,
              mois: widget.mois,
              annee: widget.annee,
              salaireBase: _salaireBase,
              primes: double.tryParse(_primesCtrl.text) ?? 0,
              bonus: double.tryParse(_bonusCtrl.text) ?? 0,
              heuresSupp: double.tryParse(_heureSuppCtrl.text) ?? 0,
              tauxHeureSupp: double.tryParse(_tauxCtrl.text) ?? 0,
              retenues: double.tryParse(_retenuesCtrl.text) ?? 0,
              cotisationsSociales: double.tryParse(_cotisCtrl.text) ?? 0,
              impots: double.tryParse(_impotsCtrl.text) ?? 0,
              netAPayer: _net,
              createdAt: DateTime.now(),
              createdBy: user.id,
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Fiche de paie créée');
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
              'Nouvelle fiche de paie',
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
                    _salaireBase = emp.salaire;
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
            if (_salaireBase > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Salaire de base: ${NumberFormat('#,###').format(_salaireBase)} FCFA',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Primes',
                    controller: _primesCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Bonus',
                    controller: _bonusCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Heures supp.',
                    controller: _heureSuppCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Taux/heure',
                    controller: _tauxCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Cotisations',
                    controller: _cotisCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Impôts',
                    controller: _impotsCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Retenues diverses',
              controller: _retenuesCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NET À PAYER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(_net)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: const Text('Créer la fiche de paie'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
