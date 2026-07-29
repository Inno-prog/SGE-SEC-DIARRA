import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../utils/document_viewer.dart';
import '../../models/employee_model.dart';
import '../../models/models.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final String id;
  const EmployeeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empAsync = ref
        .watch(allEmployeesProvider)
        .whenData(
          (list) => list.firstWhere(
            (e) => e.id == id,
            orElse: () => throw Exception('Not found'),
          ),
        );

    return empAsync.when(
      data: (emp) => _EmployeeDetailView(employee: emp),
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Employé')),
        body: const Center(child: Text('Employé introuvable')),
      ),
    );
  }
}

class _EmployeeDetailView extends ConsumerWidget {
  final EmployeeModel employee;
  const _EmployeeDetailView({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    GoRouter.of(context).pop();
                  } else {
                    context.go('/employees');
                  }
                },
              ),
              actions: [
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.go('/employees/${employee.id}/edit'),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      EmployeeAvatar(
                        photoUrl: employee.photoUrl,
                        name: employee.fullName,
                        radius: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        employee.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${employee.poste} • ${employee.departementNom}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(status: employee.statut),
                    ],
                  ),
                ),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Infos'),
                  Tab(text: 'Contrats'),
                  Tab(text: 'Présences'),
                  Tab(text: 'Congés'),
                  Tab(text: 'Paie'),
                  Tab(text: 'Sanctions'),
                  Tab(text: 'Formations'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _InfoTab(employee: employee),
              _ContractsTab(employeeId: employee.id),
              _AttendanceTab(employeeId: employee.id),
              _LeavesTab(employeeId: employee.id),
              _PayrollTab(employeeId: employee.id),
              _SanctionsTab(employeeId: employee.id),
              _TrainingsTab(employeeId: employee.id),
              _DocumentsTab(
                employeeId: employee.id,
                employeeNom: employee.fullName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTab extends ConsumerWidget {
  final EmployeeModel employee;
  const _InfoTab({required this.employee});

  Future<void> _viewDocument(
    BuildContext context,
    WidgetRef ref,
    String? fileId,
    String fileName,
  ) async {
    if (fileId == null || fileId.isEmpty) {
      if (context.mounted)
        showSnack(context, 'Aucun document disponible', isError: true);
      return;
    }
    try {
      final service = ref.read(firestoreServiceProvider);
      final bytes = await service.getDocumentBytes(fileId);
      if (context.mounted) {
        await openDocument(bytes, service.guessMimeType(fileName), fileName);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, 'Erreur: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Informations personnelles',
          items: [
            ('Matricule', employee.matricule),
            ('Sexe', employee.sexe),
            (
              'Date de naissance',
              DateFormat('dd/MM/yyyy').format(employee.dateNaissance),
            ),
            ('Adresse', employee.adresse),
            ('Téléphone', employee.telephone),
            ('Email', employee.email),
            ('Situation matrimoniale', employee.situationMatrimoniale),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Informations professionnelles',
          items: [
            ('Poste', employee.poste),
            ('Service', employee.service),
            ('Département', employee.departementNom),
            ('Grade', employee.grade),
            (
              'Date d\'embauche',
              DateFormat('dd/MM/yyyy').format(employee.dateEmbauche),
            ),
            ('Type de contrat', employee.typeContrat),
            (
              'Salaire de base',
              '${NumberFormat('#,###').format(employee.salaire)} FCFA',
            ),
            ('Ancienneté', '${employee.anciennete} an(s)'),
          ],
        ),
        if (employee.contactUrgence != null) ...[
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Contact d\'urgence',
            items: [
              ('Nom', employee.contactUrgence!.nom),
              ('Téléphone', employee.contactUrgence!.telephone),
              ('Relation', employee.contactUrgence!.relation),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Solde de congés',
          items: [
            ('Congés annuels', '${employee.soldeCongesAnnuels} jours'),
            ('Congés maladie', '${employee.soldeCongesMaladie} jours'),
          ],
        ),
        const SizedBox(height: 16),
        _DocCard(
          employee: employee,
          onViewDocument: (fileId, fileName) =>
              _viewDocument(context, ref, fileId, fileName),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final EmployeeModel employee;
  final Future<void> Function(String? fileId, String fileName) onViewDocument;

  const _DocCard({required this.employee, required this.onViewDocument});

  @override
  Widget build(BuildContext context) {
    final docs = [
      ('Contrat signé', employee.contratSigneFileId, 'contrat_signe.pdf'),
      ('Demande', employee.demandeFileId, 'demande.pdf'),
      ('CV', employee.cvFileId, 'cv.pdf'),
      ('Diplôme', employee.diplomeFileId, 'diplome.pdf'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 20),
            ...docs.map((doc) {
              final label = doc.$1;
              final fileId = doc.$2;
              final fileName = doc.$3;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 13)),
                    ),
                    if (fileId != null && fileId.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => onViewDocument(fileId, fileName),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Voir'),
                      )
                    else
                      Text(
                        'Non fourni',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  final String employeeId;
  const _ContractsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsProvider(employeeId));
    return contracts.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucun contrat',
              icon: Icons.description_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _ContractCard(contract: list[i]),
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractModel contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          contract.type,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Du ${DateFormat('dd/MM/yyyy').format(contract.dateDebut)}${contract.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(contract.dateFin!)}' : ' (indéterminé)'}',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusBadge(status: contract.statut),
            if (contract.isExpiringSoon)
              const Text(
                '⚠️ Expire bientôt',
                style: TextStyle(fontSize: 10, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  final String employeeId;
  const _AttendanceTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(
      attendanceProvider(AttendanceParams(employeeId: employeeId)),
    );
    return attendance.when(
      data: (list) => list.isEmpty
          ? const EmptyState(message: 'Aucun pointage', icon: Icons.fingerprint)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final a = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.fingerprint,
                      color: AppColors.primary,
                    ),
                    title: Text(DateFormat('dd/MM/yyyy').format(a.date)),
                    subtitle: Text(
                      a.heureArrivee != null
                          ? 'Arrivée: ${DateFormat('HH:mm').format(a.heureArrivee!)}${a.heureDepart != null ? ' • Départ: ${DateFormat('HH:mm').format(a.heureDepart!)}' : ''}'
                          : '—',
                    ),
                    trailing: StatusBadge(status: a.statut),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          'Erreur: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _LeavesTab extends ConsumerWidget {
  final String employeeId;
  const _LeavesTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(
      leavesProvider(LeaveParams(employeeId: employeeId)),
    );
    return leaves.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucun congé',
              icon: Icons.beach_access_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final l = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.beach_access_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      l.type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(l.dateDebut)} → ${DateFormat('dd/MM/yyyy').format(l.dateFin)} (${l.nombreJours}j)',
                    ),
                    trailing: StatusBadge(status: l.statut),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _PayrollTab extends ConsumerWidget {
  final String employeeId;
  const _PayrollTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payroll = ref.watch(
      payrollProvider(PayrollParams(employeeId: employeeId)),
    );
    final months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return payroll.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucune fiche de paie',
              icon: Icons.payments_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      '${months[p.mois]} ${p.annee}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Brut: ${NumberFormat('#,###').format(p.brutTotal)} FCFA',
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(p.netAPayer)} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        StatusBadge(status: p.statut),
                      ],
                    ),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _SanctionsTab extends ConsumerWidget {
  final String employeeId;
  const _SanctionsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanctions = ref.watch(sanctionsProvider(employeeId));
    return sanctions.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucune sanction',
              icon: Icons.gavel_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.gavel_outlined,
                      color: AppColors.error,
                    ),
                    title: Text(
                      s.type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(s.motif),
                    trailing: Text(
                      DateFormat('dd/MM/yyyy').format(s.date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _TrainingsTab extends ConsumerWidget {
  final String employeeId;
  const _TrainingsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainings = ref.watch(trainingsProvider(employeeId));
    return trainings.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucune formation',
              icon: Icons.school_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final t = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      t.intitule,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${t.organisme} • ${t.dureeJours}j'),
                    trailing: Text(
                      DateFormat('dd/MM/yyyy').format(t.date),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  final String employeeId;
  final String employeeNom;
  const _DocumentsTab({required this.employeeId, required this.employeeNom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider(employeeId));
    return docs.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              message: 'Aucun document',
              icon: Icons.folder_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final d = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      d.nom,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(d.type),
                    trailing: Text(
                      DateFormat('dd/MM/yyyy').format(d.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
