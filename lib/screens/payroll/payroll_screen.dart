import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/constants/app_constants.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;
  String _search = '';

  static const _months = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final payroll = ref.watch(payrollProvider(PayrollParams(month: _mois, year: _annee)));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Gestion de la paie'),
        actions: [NotificationBell()],
      ),
      body: payroll.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered.where((p) => p.employeeNom.toLowerCase().contains(q)).toList();
          }

          final totalNet = filtered.fold<double>(0, (s, p) => s + p.netAPayer);

          return _PayrollPageContent(
            payrolls: filtered,
            mois: _mois,
            annee: _annee,
            months: _months,
            totalNet: totalNet,
            search: _search,
            onSearch: (v) => setState(() => _search = v),
            onPrevMonth: () => setState(() {
              if (_mois == 1) { _mois = 12; _annee--; } else { _mois--; }
            }),
            onNextMonth: () => setState(() {
              if (_mois == 12) { _mois = 1; _annee++; } else { _mois++; }
            }),
            onAdd: () => _showPayrollForm(context),
            onView: (p) => _showDetail(context, p),
            onDelete: (p) async {
              final ok = await showConfirm(
                context,
                title: 'Supprimer la fiche de paie',
                message: 'Supprimer la fiche de ${p.employeeNom} ?',
              );
              if (ok && context.mounted) {
                await ref.read(payrollApiServiceProvider).deletePayroll(p.id);
                if (context.mounted) showSnack(context, 'Fiche supprimée');
              }
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _showPayrollForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
          child: _PayrollForm(mois: _mois, annee: _annee),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, PayrollModel payroll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détail — ${payroll.employeeNom}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _DetailRow('Salaire de base', '${NumberFormat('#,###').format(payroll.salaireBase)} FCFA'),
              if (payroll.primes > 0)
                _DetailRow('Primes', '${NumberFormat('#,###').format(payroll.primes)} FCFA', color: AppColors.success),
              if (payroll.heuresSupp > 0)
                _DetailRow('Heures sup.', '${payroll.heuresSupp}h × ${NumberFormat('#,###').format(payroll.tauxHeureSupp)} FCFA'),
              const Divider(),
              _DetailRow('Cotisations sociales', '-${NumberFormat('#,###').format(payroll.cotisationsSociales)} FCFA', color: AppColors.error),
              if (payroll.retenues > 0)
                _DetailRow('Retenues', '-${NumberFormat('#,###').format(payroll.retenues)} FCFA', color: AppColors.error),
              const Divider(),
              _DetailRow('NET À PAYER', '${NumberFormat('#,###').format(payroll.netAPayer)} FCFA', isTotal: true),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _PayrollPageContent extends ConsumerWidget {
  final List<PayrollModel> payrolls;
  final int mois;
  final int annee;
  final List<String> months;
  final double totalNet;
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onAdd;
  final void Function(PayrollModel) onView;
  final void Function(PayrollModel) onDelete;

  const _PayrollPageContent({
    required this.payrolls,
    required this.mois,
    required this.annee,
    required this.months,
    required this.totalNet,
    required this.search,
    required this.onSearch,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onAdd,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Month navigator bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrevMonth,
                ),
                Expanded(
                  child: Text(
                    '${months[mois]} $annee',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextMonth,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${NumberFormat('#,###').format(totalNet)} FCFA',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Page content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page Header
                  ProPageHeader(
                    icon: Icons.payments_outlined,
                    title: 'Fiches de paie',
                    subtitle: '${months[mois]} $annee — Masse salariale',
                    count: payrolls.length,
                  ),
                  const SizedBox(height: 16),
                  // Toolbar
                  ProListToolbar(
                    searchHint: 'Rechercher un employé...',
                    onSearch: onSearch,
                    addLabel: 'Nouvelle fiche',
                    onAdd: onAdd,
                  ),
                  const SizedBox(height: 16),
                  // Data Table
                  ProDataTable<PayrollModel>(
                    minWidth: 1100,
                    columns: _buildColumns(context: context),
                    items: payrolls,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ProColumn<PayrollModel>> _buildColumns({required BuildContext context}) {
    return [
      ProColumn<PayrollModel>(
        label: 'Employé',
        flex: 3,
        cell: (p) => ProEmployeeCell(
          name: p.employeeNom,
          subtitle: 'Employé',
        ),
      ),
      ProColumn<PayrollModel>(
        label: 'Salaire base',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Text('${NumberFormat('#,###').format(p.salaireBase)} FCFA'),
      ),
      ProColumn<PayrollModel>(
        label: 'Primes',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Text(
          '${NumberFormat('#,###').format(p.primes)} FCFA',
          style: TextStyle(color: p.primes > 0 ? AppColors.success : AppColors.textSecondary),
        ),
      ),
      ProColumn<PayrollModel>(
        label: 'Heures sup.',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => p.heuresSupp > 0
            ? Text('${p.heuresSupp}h × ${NumberFormat('#,###').format(p.tauxHeureSupp)} FCFA')
            : const Text('—'),
      ),
      ProColumn<PayrollModel>(
        label: 'Cotisations',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Text(
          '-${NumberFormat('#,###').format(p.cotisationsSociales)} FCFA',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      ProColumn<PayrollModel>(
        label: 'Retenues',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => p.retenues > 0
            ? Text(
                '-${NumberFormat('#,###').format(p.retenues)} FCFA',
                style: const TextStyle(color: AppColors.error),
              )
            : const Text('—'),
      ),
      ProColumn<PayrollModel>(
        label: 'Net à payer',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Text(
          '${NumberFormat('#,###').format(p.netAPayer)} FCFA',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
      ProColumn<PayrollModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.picture_as_pdf,
              color: Colors.red.shade700,
              tooltip: 'PDF',
              onTap: () => _downloadPayrollPdf(context, p),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.visibility_outlined,
              color: Colors.blue.shade700,
              tooltip: 'Voir',
              onTap: () => onView(p),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () => onDelete(p),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _downloadPayrollPdf(BuildContext context, PayrollModel payroll) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Fiche de paie',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy').format(now)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Employé: ${payroll.employeeNom}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Période: ${months[payroll.mois]} ${payroll.annee}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Détails',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ..._buildPayrollDetailTable(payroll),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final filename =
        'fiche_paie_${payroll.employeeNom.replaceAll(' ', '_')}_${months[payroll.mois]}_${payroll.annee}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: filename,
    );
    if (context.mounted) showSnack(context, 'PDF généré avec succès');
  }

  List<pw.Widget> _buildPayrollDetailTable(PayrollModel payroll) {
    final rows = <pw.TableRow>[
      _buildPdfRow('Salaire de base', '${NumberFormat('#,###').format(payroll.salaireBase)} FCFA'),
      if (payroll.primes > 0)
        _buildPdfRow('Primes', '${NumberFormat('#,###').format(payroll.primes)} FCFA', color: PdfColors.green),
      if (payroll.heuresSupp > 0)
        _buildPdfRow('Heures sup.', '${payroll.heuresSupp}h × ${NumberFormat('#,###').format(payroll.tauxHeureSupp)} FCFA'),
      _buildPdfRow('Cotisations sociales', '-${NumberFormat('#,###').format(payroll.cotisationsSociales)} FCFA', color: PdfColors.red),
      if (payroll.retenues > 0)
        _buildPdfRow('Retenues', '-${NumberFormat('#,###').format(payroll.retenues)} FCFA', color: PdfColors.red),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('NET À PAYER',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('${NumberFormat('#,###').format(payroll.netAPayer)} FCFA',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          ),
        ],
      ),
    ];

    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.5),
        },
        children: rows,
      ),
    ];
  }

  pw.TableRow _buildPdfRow(String label, String value, {PdfColor? color}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 9, color: color)),
        ),
      ],
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
  final _heureSuppCtrl = TextEditingController();
  final _tauxCtrl = TextEditingController();
  final _retenuesCtrl = TextEditingController();
  final _cotisCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  double _salaireBase = 0;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_primesCtrl, _heureSuppCtrl, _tauxCtrl, _retenuesCtrl, _cotisCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _net {
    final brut = _salaireBase +
        (double.tryParse(_primesCtrl.text) ?? 0) +
        ((double.tryParse(_heureSuppCtrl.text) ?? 0) * (double.tryParse(_tauxCtrl.text) ?? 0));
    return brut - (double.tryParse(_cotisCtrl.text) ?? 0) - (double.tryParse(_retenuesCtrl.text) ?? 0);
  }

  Future<void> _save() async {
    if (_employeeId == null) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      await ref.read(payrollApiServiceProvider).createPayroll(
        PayrollModel(
          id: '',
          employeeId: _employeeId!,
          employeeNom: _employeeNom!,
          mois: widget.mois,
          annee: widget.annee,
          salaireBase: _salaireBase,
          primes: double.tryParse(_primesCtrl.text) ?? 0,
          heuresSupp: double.tryParse(_heureSuppCtrl.text) ?? 0,
          tauxHeureSupp: double.tryParse(_tauxCtrl.text) ?? 0,
          retenues: double.tryParse(_retenuesCtrl.text) ?? 0,
          cotisationsSociales: double.tryParse(_cotisCtrl.text) ?? 0,
          netAPayer: _net,
          createdAt: DateTime.now(),
          createdBy: user.id,
        ),
      );
      ref.invalidate(payrollProvider(PayrollParams(month: widget.mois, year: widget.annee)));
      ref.invalidate(allPayrollsProvider);
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
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle fiche de paie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            employees.when(
              data: (list) => AppDropdown<String>(
                label: 'Employé *',
                value: _employeeId,
                items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final emp = list.firstWhere((e) => e.id == v);
                  setState(() {
                    _employeeId = v;
                    _employeeNom = emp.fullName;
                    _salaireBase = emp.salaire;
                  });
                  final bonuses = await ref.read(bonusesProvider(BonusParams(employeeId: v, status: 'active')).future);
                  final totalPrimes = bonuses.where((b) => b.statut == 'active').fold<double>(0, (s, b) => s + b.montant);
                  _primesCtrl.text = totalPrimes.toStringAsFixed(0);
                  _cotisCtrl.text = (_salaireBase * AppConstants.tauxCotisationsSociales).toStringAsFixed(0);
                  _retenuesCtrl.text = '0';
                  _heureSuppCtrl.text = '0';
                  _tauxCtrl.text = '0';
                  if (mounted) setState(() {});
                },
              ),
              loading: () => const SizedBox(),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 12),
            if (_salaireBase > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Salaire de base: ${NumberFormat('#,###').format(_salaireBase)} FCFA',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),
            AppTextField(label: 'Primes', controller: _primesCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Heures supp.', controller: _heureSuppCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Taux/heure', controller: _tauxCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Cotisations sociales (22%)', controller: _cotisCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            AppTextField(label: 'Retenues diverses', controller: _retenuesCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NET À PAYER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${NumberFormat('#,###').format(_net)} FCFA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Créer la fiche de paie')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool isTotal;
  const _DetailRow(this.label, this.value, {this.color, this.isTotal = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
            Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: color ?? (isTotal ? AppColors.primary : AppColors.textPrimary))),
          ],
        ),
      );
}