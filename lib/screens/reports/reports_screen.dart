import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/user_model.dart';
import '../../models/models.dart';
import '../../models/employee_model.dart';

// ─── Reports ─────────────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      ('Rapport des présences', Icons.fingerprint, AppColors.primary),
      ('Rapport des congés', Icons.beach_access_outlined, AppColors.info),
      ('Rapport des employés', Icons.people_outline, AppColors.accent),
      ('Rapport des formations', Icons.school_outlined, AppColors.warning),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Rapports'),
        actions: [NotificationBell()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Générer des rapports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Exportez vos données en PDF ou Excel',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...reports.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: r.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.$2, color: r.$3),
                ),
                title: Text(
                  r.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        _generateReportPdf(context, r.$1, ref);
                      },
                      tooltip: 'PDF',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.table_chart_outlined,
                        color: AppColors.success,
                      ),
                      onPressed: () =>
                          showSnack(context, 'Génération Excel en cours...'),
                      tooltip: 'Excel',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Journal des actions'),
          const SizedBox(height: 12),
          Consumer(
            builder: (_, ref, __) {
              final logs = ref.watch(auditLogsProvider);
              return logs.when(
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        message: 'Aucune action enregistrée',
                        icon: Icons.history,
                      )
                    : Column(
                        children: list
                            .take(20)
                            .map(
                              (l) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _actionColor(
                                          l.action,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        _actionIcon(l.action),
                                        color: _actionColor(l.action),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Par ${l.userNom} • ${DateFormat('dd/MM/yyyy HH:mm').format(l.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const LoadingWidget(),
                error: (e, _) => Center(
                  child: Text(
                    "Erreur: $e",
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateReportPdf(
    BuildContext context,
    String reportName,
    WidgetRef ref,
  ) async {
    final user = ref.read(currentUserProvider);
    final attendanceService = ref.read(attendanceApiServiceProvider);
    final leaveService = ref.read(leaveApiServiceProvider);
    final employeeService = ref.read(employeeApiServiceProvider);
    final trainingService = ref.read(trainingApiServiceProvider);
    final pdf = pw.Document();
    final now = DateTime.now();
    final period = DateFormat('MM/yyyy').format(now);

    List<dynamic> data = [];
    String subtitle = '';

    switch (reportName) {
      case 'Rapport des présences':
        final response = await attendanceService.getAttendances();
        data = (response['data'] as List? ?? []).map((e) => AttendanceModel.fromJson(e)).toList();
        subtitle = 'Total pointages: ${data.length}';
        break;
      case 'Rapport des congés':
        final response = await leaveService.getLeaves();
        data = (response['data'] as List? ?? []).map((e) => LeaveModel.fromJson(e)).toList();
        subtitle = 'Total demandes: ${data.length}';
        break;
      case 'Rapport des employés':
        final response = await employeeService.getEmployees();
        data = (response['data'] as List? ?? []).map((e) => EmployeeModel.fromJson(e)).toList();
        subtitle = 'Total employés: ${data.length}';
        break;
      case 'Rapport des formations':
        final response = await trainingService.getTrainings();
        data = (response['data'] as List? ?? []).map((e) => TrainingModel.fromJson(e)).toList();
        subtitle = 'Total formations: ${data.length}';
        break;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                reportName,
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
                      'Rapport: $reportName',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Période: $period',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(subtitle, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      generatedBy(user),
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
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
              if (data.isEmpty)
                pw.Text(
                  'Aucune donnée disponible',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                )
              else
                ..._buildReportTables(reportName, data),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final filename =
        '${reportName.replaceAll(' ', '_')}_${DateFormat('yyyyMM').format(now)}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: filename,
    );
    if (context.mounted) showSnack(context, 'PDF généré avec succès');
  }

  List<pw.Widget> _buildReportTables(String reportName, List<dynamic> data) {
    switch (reportName) {
      case 'Rapport des présences':
        return _buildAttendanceTable(data.cast<AttendanceModel>());
      case 'Rapport des congés':
        return _buildLeaveTable(data.cast<LeaveModel>());
      case 'Rapport des employés':
        return _buildEmployeeTable(data.cast<EmployeeModel>());
      case 'Rapport des formations':
        return _buildTrainingTable(data.cast<TrainingModel>());
      default:
        return [pw.Text('Type de rapport non supporté')];
    }
  }

  List<pw.Widget> _buildAttendanceTable(List<AttendanceModel> items) {
    final headers = [
      'Employé',
      'Date',
      'Arrivée',
      'Départ',
      'Statut',
      'Méthode',
      'Retard (min)',
      'Justification',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.2),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1),
          6: pw.FlexColumnWidth(1),
          7: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final a in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    a.employeeNom,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(a.date),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    a.heureArrivee != null
                        ? DateFormat('HH:mm').format(a.heureArrivee!)
                        : '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    a.heureDepart != null
                        ? DateFormat('HH:mm').format(a.heureDepart!)
                        : '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(a.statut, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(a.methode, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${a.retardMinutes}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    a.justification ?? '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildPayrollTable(List<PayrollModel> items) {
    final headers = [
      'Employé',
      'Mois',
      'Année',
      'Base',
      'Primes',
      'Bonus',
      'H.Supp',
      'Brut',
      'Retenues',
      'Cot.',
      'Impôts',
      'Net',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(0.8),
          2: pw.FlexColumnWidth(0.8),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1),
          6: pw.FlexColumnWidth(1),
          7: pw.FlexColumnWidth(1),
          8: pw.FlexColumnWidth(1),
          9: pw.FlexColumnWidth(1),
          10: pw.FlexColumnWidth(1),
          11: pw.FlexColumnWidth(1.2),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final p in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    p.employeeNom,
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${p.mois}', style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${p.annee}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.salaireBase)}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.primes)}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.bonus)}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.heuresSupp * p.tauxHeureSupp)}',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.brutTotal)}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.retenues)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.cotisationsSociales)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.impots)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${NumberFormat('#,###').format(p.netAPayer)}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildLeaveTable(List<LeaveModel> items) {
    final headers = [
      'Employé',
      'Type',
      'Du',
      'Au',
      'Jours',
      'Motif',
      'Statut',
      'Validé par',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(0.8),
          5: pw.FlexColumnWidth(2),
          6: pw.FlexColumnWidth(1),
          7: pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final l in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    l.employeeNom,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(l.type, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(l.dateDebut),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(l.dateFin),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${l.nombreJours}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(l.motif, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(l.statut, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    l.validePar ?? '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildEmployeeTable(List<EmployeeModel> items) {
    final headers = [
      'Matricule',
      'Nom complet',
      'Département',
      'Poste',
      'Grade',
      'Contrat',
      'Date embauche',
      'Statut',
      'Solde congé',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1.2),
          3: pw.FlexColumnWidth(1.2),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1),
          6: pw.FlexColumnWidth(1),
          7: pw.FlexColumnWidth(1),
          8: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final e in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(e.matricule, style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(e.fullName, style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    e.departementNom,
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(e.poste, style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(e.grade, style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    e.typeContrat,
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(e.dateEmbauche),
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(e.statut, style: pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${e.soldeCongesAnnuels}j',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildSanctionTable(List<SanctionModel> items) {
    final headers = [
      'Employé',
      'Type',
      'Motif',
      'Date',
      'Durée (jours)',
      'Décision par',
      'Statut',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1.5),
          6: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final s in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    s.employeeNom,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(s.type, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(s.motif, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(s.date),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    s.dureeSuspension != null ? '${s.dureeSuspension}' : '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    s.decisionPar ?? '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(s.statut, style: pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildTrainingTable(List<TrainingModel> items) {
    final headers = [
      'Employé',
      'Intitulé',
      'Date',
      'Organisme',
      'Durée (jours)',
      'Attestation',
      'Notes',
    ];
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(1.5),
          4: pw.FlexColumnWidth(1),
          5: pw.FlexColumnWidth(1.5),
          6: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          for (final t in items)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    t.employeeNom,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(t.intitule, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(t.date),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(t.organisme, style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${t.dureeJours}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    t.attestationUrl != null ? 'Oui' : 'Non',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    t.notes ?? '-',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
        ],
      ),
    ];
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'ajout':
        return AppColors.success;
      case 'modification':
        return AppColors.warning;
      case 'suppression':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'ajout':
        return Icons.add_circle_outline;
      case 'modification':
        return Icons.edit_outlined;
      case 'suppression':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }
}

// ─── Settings ────────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Cabinet',
            items: [
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Informations du cabinet',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.image_outlined,
                title: 'Logo',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.attach_money_outlined,
                title: 'Devise',
                subtitle: 'FCFA',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.access_time_outlined,
                title: 'Fuseau horaire',
                subtitle: 'Burkina Faso/Ouagadougou',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Apparence',
            items: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Couleurs',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Mode sombre',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Données',
            items: [
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Sauvegarde automatique',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Exporter les données',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                title: 'Restaurer une sauvegarde',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            items: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications push',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Notifications email',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Version'),
              trailing: const Text(
                AppConstants.appVersion,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String generatedBy(UserModel? user) {
  return user != null ? 'Genere par ${user.fullName}' : '';
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < items.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}

