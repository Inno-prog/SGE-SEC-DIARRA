import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingWidget();

    return switch (user.role) {
      AppConstants.roleEmployee => _EmployeeDashboard(userId: user.id),
      AppConstants.roleChefService => _ChefServiceDashboard(),
      AppConstants.roleRH => _RHDashboard(),
      _ => _AdminDashboard(), // admin + director
    };
  }
}

// ─── Admin / RH / Director Dashboard ─────────────────────────────────────────
class _AdminDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final pendingLeaves = ref.watch(pendingLeavesProvider);
    final expiringContracts = ref.watch(expiringContractsProvider);

    final prenom = ref.watch(currentUserProvider)?.prenom ?? '';
    return Scaffold(
      appBar: _GradientAppBar(
        prenom: prenom,
        onMenuTap: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: stats.when(
                  data: (data) => _StatsGrid(stats: data),
                  loading: () =>
                      const SizedBox(height: 200, child: LoadingWidget()),
                  error: (e, _) => Center(
                    child: Text(
                      "Erreur: $e",
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              // Alertes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AlertsSection(
                  pendingLeaves: pendingLeaves.value ?? [],
                  expiringContracts: expiringContracts.value ?? [],
                ),
              ),
              const SizedBox(height: 20),
              // Répartition par département
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DeptChart(),
              ),
              const SizedBox(height: 20),
              // Anniversaires
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: birthdays.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox()
                      : _BirthdaysSection(employees: list),
                  loading: () => const SizedBox(),
                  error: (e, _) => Center(
                    child: Text(
                      "Erreur: $e",
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── RH Dashboard ────────────────────────────────────────────────────────
class _RHDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final pendingLeaves = ref.watch(pendingLeavesProvider);
    final expiringContracts = ref.watch(expiringContractsProvider);

    final prenom = ref.watch(currentUserProvider)?.prenom ?? '';
    return Scaffold(
      appBar: _GradientAppBar(
        prenom: prenom,
        onMenuTap: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Stats Grid (sans les indicateurs financiers)
              Padding(
                padding: const EdgeInsets.all(16),
                child: stats.when(
                  data: (data) => _StatsGrid(stats: data),
                  loading: () =>
                      const SizedBox(height: 200, child: LoadingWidget()),
                  error: (e, _) => Center(
                    child: Text(
                      "Erreur: $e",
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              // Alertes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AlertsSection(
                  pendingLeaves: pendingLeaves.value ?? [],
                  expiringContracts: expiringContracts.value ?? [],
                ),
              ),
              const SizedBox(height: 20),
              // Répartition par département
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DeptChart(),
              ),
              const SizedBox(height: 20),
              // Anniversaires
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: birthdays.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox()
                      : _BirthdaysSection(employees: list),
                  loading: () => const SizedBox(),
                  error: (e, _) => Center(
                    child: Text(
                      "Erreur: $e",
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Total Employés',
        '${stats['totalEmployes'] ?? 0}',
        Icons.people_outline,
        AppColors.primary,
        AppRoutes.employees,
        null,
      ),
      (
        'Présents aujourd\'hui',
        '${stats['presents_aujourd_hui'] ?? 0}',
        Icons.check_circle_outline,
        AppColors.success,
        AppRoutes.attendance,
        null,
      ),
      (
        'En congé',
        '${stats['en_conge'] ?? 0}',
        Icons.beach_access_outlined,
        AppColors.info,
        AppRoutes.leaves,
        null,
      ),
      (
        'Congés en attente',
        '${stats['conges_en_attente'] ?? 0}',
        Icons.pending_outlined,
        AppColors.warning,
        AppRoutes.leaves,
        stats['conges_en_attente'] != null && stats['conges_en_attente']! > 0
            ? '!'
            : null,
      ),
      (
        'Contrats actifs',
        '${stats['contrats_actifs'] ?? 0}',
        Icons.description_outlined,
        AppColors.accent,
        AppRoutes.contracts,
        null,
      ),
      (
        'Employés actifs',
        '${stats['employes_actifs'] ?? 0}',
        Icons.person_outline,
        AppColors.primaryLight,
        AppRoutes.employees,
        null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => StatCard(
        title: items[i].$1,
        value: items[i].$2,
        icon: items[i].$3,
        color: items[i].$4,
        subtitle: items[i].$6,
        onTap: () => context.go(items[i].$5),
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final List pendingLeaves;
  final List expiringContracts;
  const _AlertsSection({
    required this.pendingLeaves,
    required this.expiringContracts,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingLeaves.isEmpty && expiringContracts.isEmpty)
      return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '⚠️ Alertes'),
        const SizedBox(height: 12),
        if (pendingLeaves.isNotEmpty)
          _AlertTile(
            icon: Icons.beach_access_outlined,
            color: AppColors.warning,
            message:
                '${pendingLeaves.length} demande(s) de congé en attente de validation',
            onTap: () => context.go(AppRoutes.leaves),
          ),
        if (expiringContracts.isNotEmpty)
          _AlertTile(
            icon: Icons.description_outlined,
            color: AppColors.error,
            message:
                '${expiringContracts.length} contrat(s) expirent dans moins de 30 jours',
            onTap: () => context.go(AppRoutes.contracts),
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback onTap;
  const _AlertTile({
    required this.icon,
    required this.color,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

class _DeptChart extends ConsumerWidget {
  const _DeptChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depts = ref.watch(departmentsProvider);
    return depts.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox();
        final total = list.fold<int>(0, (s, d) => s + d.nombreEmployes);
        if (total == 0) return const SizedBox();
        final colors = [
          AppColors.primary,
          AppColors.accent,
          AppColors.info,
          AppColors.success,
          AppColors.warning,
          AppColors.gold,
        ];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Répartition par département'),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: PieChart(
                      PieChartData(
                        sections: list.asMap().entries.map((e) {
                          final pct = total > 0
                              ? e.value.nombreEmployes / total * 100
                              : 0.0;
                          return PieChartSectionData(
                            value: e.value.nombreEmployes.toDouble(),
                            color: colors[e.key % colors.length],
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: list
                          .asMap()
                          .entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[e.key % colors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.value.nom,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${e.value.nombreEmployes}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, _) => Center(
        child: Text(
          "Erreur: $e",
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _BirthdaysSection extends StatelessWidget {
  final List employees;
  const _BirthdaysSection({required this.employees});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🎂 Anniversaires du mois'),
        const SizedBox(height: 12),
        ...employees.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                EmployeeAvatar(
                  photoUrl: e.photoUrl,
                  name: e.fullName,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  DateFormat('d MMMM', 'fr_FR').format(e.dateNaissance),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🎂'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chef de Service Dashboard ────────────────────────────────────────────────
class _ChefServiceDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final pendingLeaves = ref.watch(pendingLeavesProvider);

    return Scaffold(
      appBar: _GradientAppBar(
        prenom: user.prenom,
        onMenuTap: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  title: 'Mon équipe',
                  value: '—',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                  onTap: () => context.go(AppRoutes.employees),
                ),
                StatCard(
                  title: 'Congés en attente',
                  value: '${pendingLeaves.value?.length ?? 0}',
                  icon: Icons.pending_outlined,
                  color: AppColors.warning,
                  onTap: () => context.go(AppRoutes.leaves),
                ),
                StatCard(
                  title: 'Présences',
                  value: '—',
                  icon: Icons.fingerprint,
                  color: AppColors.success,
                  onTap: () => context.go(AppRoutes.attendance),
                ),
                StatCard(
                  title: 'Agenda',
                  value: '—',
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.info,
                  onTap: () => context.go(AppRoutes.agenda),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Employee Dashboard ───────────────────────────────────────────────────────
class _EmployeeDashboard extends ConsumerWidget {
  final String userId;
  const _EmployeeDashboard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final myLeaves = ref.watch(
      leavesProvider(LeaveParams(employeeId: user.employeeId)),
    );

    return Scaffold(
      appBar: _GradientAppBar(
        prenom: user.prenom,
        onMenuTap: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        title: 'Mes congés',
                        value: '${myLeaves.value?.length ?? 0}',
                        icon: Icons.beach_access_outlined,
                        color: AppColors.primary,
                        onTap: () => context.go(AppRoutes.leaves),
                      ),
                      StatCard(
                        title: 'Messages',
                        value: '—',
                        icon: Icons.chat_outlined,
                        color: AppColors.info,
                        onTap: () => context.go(AppRoutes.messaging),
                      ),
                      StatCard(
                        title: 'Documents',
                        value: '—',
                        icon: Icons.folder_outlined,
                        color: AppColors.accent,
                        onTap: () => context.go(AppRoutes.documents),
                      ),
                      StatCard(
                        title: 'Agenda',
                        value: '—',
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.success,
                        onTap: () => context.go(AppRoutes.agenda),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Mes dernières demandes de congé'),
                  const SizedBox(height: 12),
                  myLeaves.when(
                    data: (list) => list.isEmpty
                        ? const EmptyState(message: 'Aucune demande de congé')
                        : Column(
                            children: list
                                .take(3)
                                .map((l) => _LeaveCard(leave: l))
                                .toList(),
                          ),
                    loading: () => const LoadingWidget(),
                    error: (e, _) => Center(
                      child: Text(
                        "Erreur: $e",
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final dynamic leave;
  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.beach_access_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.type,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${leave.nombreJours} jour(s)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: leave.statut),
        ],
      ),
    );
  }
}

class _GradientAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String prenom;
  final VoidCallback onMenuTap;
  const _GradientAppBar({required this.prenom, required this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenuTap,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $prenom',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              NotificationBell(),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
