import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';

// ─── Absences ────────────────────────────────────────────────────────────────
class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider(const AttendanceParams()));
    return Scaffold(
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
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brut: ${NumberFormat('#,###').format(payroll.brutTotal)} FCFA',
              style: const TextStyle(fontSize: 12),
            ),
            if (payroll.primes > 0 || payroll.bonus > 0)
              Text(
                'Primes/Bonus: ${NumberFormat('#,###').format(payroll.primes + payroll.bonus)} FCFA',
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
            Text(
              'Net: ${NumberFormat('#,###').format(payroll.netAPayer)} FCFA',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (payroll.statut == 'paye')
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Payé',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => _changeStatus(
                  context,
                  ref,
                  'paye',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Marquer payé'),
              ),
          ],
        ),
        onTap: () => _showDetail(context, ref),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    if (payroll.statut == 'paye' && newStatus == 'brouillon') return;
    try {
      final updated = payroll.copyWith(
        statut: newStatus,
        datePaiement: newStatus == 'paye' ? DateTime.now() : null,
      );
      await ref.read(firestoreServiceProvider).updatePayroll(updated);
      if (context.mounted) {
        showSnack(
          context,
          'Fiche de paie marquée comme ${newStatus == 'paye' ? 'payée' : 'brouillon'}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnack(context, 'Erreur: $e', isError: true);
      }
    }
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
                _generatePayrollPdf(ctx, payroll, ref);
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePayrollPdf(
    BuildContext context,
    PayrollModel payroll,
    WidgetRef ref,
  ) async {
    final user = ref.read(currentUserProvider);
    final pdf = pw.Document();
    final moisStr = (() {
      const map = {1: 'Janvier', 2: 'Février', 3: 'Mars', 4: 'Avril', 5: 'Mai', 6: 'Juin', 7: 'Juillet', 8: 'Août', 9: 'Septembre', 10: 'Octobre', 11: 'Novembre', 12: 'Décembre'};
      return map[payroll.mois] ?? '';
    })();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fiche de Paie', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('$moisStr ${payroll.annee}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Employe: ${payroll.employeeNom}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('ID: ${payroll.employeeId}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text('Statut: ${payroll.statut}', style: pw.TextStyle(fontSize: 10, color: payroll.statut == 'paye' ? PdfColors.green700 : PdfColors.black)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _pdfTable(payroll),
              pw.SizedBox(height: 16),
              pw.Text(generatedBy(user), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final filename = 'Fiche_Paie_${payroll.employeeNom.replaceAll(' ', '_')}_${moisStr}_${payroll.annee}.pdf';
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes, name: filename);
    if (context.mounted) showSnack(context, 'PDF genere avec succes');
  }
}

pw.Widget _pdfTable(PayrollModel payroll) {
  return pw.Table(
    children: [
      pw.TableRow(children: [pw.Text('Salaire de base', style: pw.TextStyle(fontSize: 10)), pw.Text('${NumberFormat('#,###').format(payroll.salaireBase)} FCFA', style: pw.TextStyle(fontSize: 10))]),
      pw.TableRow(children: [pw.Text('Primes', style: pw.TextStyle(fontSize: 10)), pw.Text('${NumberFormat('#,###').format(payroll.primes)} FCFA', style: pw.TextStyle(fontSize: 10))]),
      pw.TableRow(children: [pw.Text('Bonus', style: pw.TextStyle(fontSize: 10)), pw.Text('${NumberFormat('#,###').format(payroll.bonus)} FCFA', style: pw.TextStyle(fontSize: 10))]),
      pw.TableRow(children: [pw.Text('Heures supp.', style: pw.TextStyle(fontSize: 10)), pw.Text('${NumberFormat('#,###').format(payroll.heuresSupp * payroll.tauxHeureSupp)} FCFA', style: pw.TextStyle(fontSize: 10))]),
pw.TableRow(children: [pw.Text('---', style: pw.TextStyle(fontSize: 10)), pw.Text('---', style: pw.TextStyle(fontSize: 10))]),
       pw.TableRow(children: [pw.Text('Brut total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.Text('${NumberFormat('#,###').format(payroll.brutTotal)} FCFA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]),
pw.TableRow(children: [pw.Text('---', style: pw.TextStyle(fontSize: 10)), pw.Text('---', style: pw.TextStyle(fontSize: 10))]),
       pw.TableRow(children: [pw.Text('Cotisations sociales', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)), pw.Text('-${NumberFormat('#,###').format(payroll.cotisationsSociales)} FCFA', style: pw.TextStyle(fontSize: 10, color: PdfColors.red))]),
       pw.TableRow(children: [pw.Text('Impots', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)), pw.Text('-${NumberFormat('#,###').format(payroll.impots)} FCFA', style: pw.TextStyle(fontSize: 10, color: PdfColors.red))]),
       pw.TableRow(children: [pw.Text('Retenues', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)), pw.Text('-${NumberFormat('#,###').format(payroll.retenues)} FCFA', style: pw.TextStyle(fontSize: 10, color: PdfColors.red))]),
       pw.TableRow(children: [pw.Text('---', style: pw.TextStyle(fontSize: 10)), pw.Text('---', style: pw.TextStyle(fontSize: 10))]),
       pw.TableRow(children: [pw.Text('NET A PAYER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.Text('${NumberFormat('#,###').format(payroll.netAPayer)} FCFA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]),
    ],
  );
}

String generatedBy(UserModel? user) {
  return user != null ? 'Genere par ${user.fullName}' : '';
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
            if (_employeeId != null)
              _BonusRecall(employeeId: _employeeId!),
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

class _BonusRecall extends ConsumerWidget {
  final String employeeId;
  const _BonusRecall({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonuses = ref.watch(bonusesProvider(BonusParams(employeeId: employeeId)));
    return bonuses.when(
      data: (list) {
        final activeBonuses = list.where((b) => b.statut == 'active').toList();
        if (activeBonuses.isEmpty) return const SizedBox.shrink();
        final total = activeBonuses.fold<double>(0, (sum, b) => sum + b.montant);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_outline, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Primes actives: ${NumberFormat('#,###').format(total)} FCFA',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
