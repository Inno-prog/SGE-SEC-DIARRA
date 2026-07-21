import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/employees/employees_screen.dart';
import '../../screens/employees/employee_detail_screen.dart';
import '../../screens/employees/employee_form_screen.dart';
import '../../screens/departments/departments_screen.dart';
import '../../screens/positions/positions_screen.dart';
import '../../screens/contracts/contracts_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/leaves/leaves_screen.dart';
import '../../screens/absences/absences_screen.dart';
import '../../screens/payroll/payroll_screen.dart';
import '../../screens/sanctions/sanctions_screen.dart';
import '../../screens/trainings/trainings_screen.dart';
import '../../screens/evaluations/evaluations_screen.dart';
import '../../screens/documents/documents_screen.dart';
import '../../screens/recruitment/recruitment_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/messaging/messaging_screen.dart';
import '../../screens/agenda/agenda_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/security/security_screen.dart';
import '../../screens/schedules/schedules_screen.dart';
import '../../screens/bonuses/bonuses_screen.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final initialLocation = ref.read(initialLocationProvider);

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      if (isLoading) return null;
      if (!isLoggedIn && state.matchedLocation != AppRoutes.login) return AppRoutes.login;
      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        final last = ref.read(lastLocationProvider);
        return last != AppRoutes.login ? last : AppRoutes.dashboard;
      }
      Future.microtask(() {
        if (state.matchedLocation.startsWith('/')) {
          ref.read(lastLocationProvider.notifier).state = state.matchedLocation;
        }
      });
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: AppRoutes.employees, builder: (_, __) => const EmployeesScreen()),
          GoRoute(
            path: '/employees/add',
            builder: (_, __) => const EmployeeFormScreen(),
          ),
          GoRoute(
            path: '/employees/:id',
            builder: (_, state) => EmployeeDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/employees/:id/edit',
            builder: (_, state) => EmployeeFormScreen(employeeId: state.pathParameters['id']),
          ),
          GoRoute(path: AppRoutes.departments, builder: (_, __) => const DepartmentsScreen()),
          GoRoute(path: AppRoutes.positions, builder: (_, __) => const PositionsScreen()),
          GoRoute(path: AppRoutes.contracts, builder: (_, __) => const ContractsScreen()),
          GoRoute(path: AppRoutes.attendance, builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: AppRoutes.leaves, builder: (_, __) => const LeavesScreen()),
          GoRoute(path: AppRoutes.absences, builder: (_, __) => const AbsencesScreen()),
          GoRoute(path: AppRoutes.payroll, builder: (_, __) => const PayrollScreen()),
          GoRoute(path: AppRoutes.sanctions, builder: (_, __) => const SanctionsScreen()),
          GoRoute(path: AppRoutes.trainings, builder: (_, __) => const TrainingsScreen()),
          GoRoute(path: AppRoutes.evaluations, builder: (_, __) => const EvaluationsScreen()),
          GoRoute(path: AppRoutes.documents, builder: (_, __) => const DocumentsScreen()),
          GoRoute(path: AppRoutes.recruitment, builder: (_, __) => const RecruitmentScreen()),
          GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersScreen()),
          GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.messaging, builder: (_, __) => const MessagingScreen()),
          GoRoute(path: AppRoutes.agenda, builder: (_, __) => const AgendaScreen()),
          GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
          GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
          GoRoute(path: AppRoutes.security, builder: (_, __) => const SecurityScreen()),
          GoRoute(path: AppRoutes.schedules, builder: (_, __) => const SchedulesScreen()),
          GoRoute(path: AppRoutes.bonuses, builder: (_, __) => const BonusesScreen()),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return isWide ? _WideLayout(child: child) : _NarrowLayout(child: child);
  }
}

class _WideLayout extends ConsumerWidget {
  final Widget child;
  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: _SideNav(currentLocation: location, unreadCount: unread),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  final Widget child;
  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: Drawer(
        child: _SideNav(currentLocation: GoRouterState.of(context).matchedLocation, unreadCount: 0),
      ),
      body: child,
    );
  }
}

class _SideNav extends ConsumerWidget {
  final String currentLocation;
  final int unreadCount;
  const _SideNav({required this.currentLocation, required this.unreadCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF560000), Color(0xFF8B0000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Secdiarra', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Text(
                        user.prenom.isNotEmpty ? user.prenom[0] : (user.nom.isNotEmpty ? user.nom[0] : '?'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _buildNavGroups(context, user?.role ?? 'employee'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavGroups(BuildContext context, String role) {
    final groups = _getNavGroups(role);
    final visible = groups.where((g) => g.items.isNotEmpty).toList();

    // Uniquement Admin & Directeur : menu en sections repliables
    if (role == AppConstants.roleAdmin || role == AppConstants.roleDirector) {
      return visible
          .map((g) => _NavGroupTile(group: g, currentLocation: currentLocation))
          .toList();
    }

    // Autres rôles : liste à plat (non repliable)
    return visible.expand((g) => g.items).map((item) {
      final isActive = currentLocation.startsWith(item.route);
      return _NavItem(
        icon: item.icon,
        label: item.label,
        route: item.route,
        isActive: isActive,
        badge: item.badge,
      );
    }).toList();
  }

  List<_NavGroup> _getNavGroups(String role) {
    final all = [
      _NavItemData(Icons.dashboard_outlined, 'Tableau de bord', AppRoutes.dashboard),
      _NavItemData(Icons.people_outline, 'Employés', AppRoutes.employees),
      _NavItemData(Icons.business_outlined, 'Départements', AppRoutes.departments),
      _NavItemData(Icons.work_outline, 'Postes', AppRoutes.positions),
      _NavItemData(Icons.description_outlined, 'Contrats', AppRoutes.contracts),
      _NavItemData(Icons.fingerprint, 'Présences', AppRoutes.attendance),
      _NavItemData(Icons.beach_access_outlined, 'Congés', AppRoutes.leaves),
      _NavItemData(Icons.event_busy_outlined, 'Absences', AppRoutes.absences),
      _NavItemData(Icons.schedule_outlined, 'Horaires', AppRoutes.schedules),
      _NavItemData(Icons.payments_outlined, 'Paie', AppRoutes.payroll),
      _NavItemData(Icons.star_outline, 'Primes', AppRoutes.bonuses),
      _NavItemData(Icons.gavel_outlined, 'Sanctions', AppRoutes.sanctions),
      _NavItemData(Icons.school_outlined, 'Formations', AppRoutes.trainings),
      _NavItemData(Icons.assessment_outlined, 'Évaluations', AppRoutes.evaluations),
      _NavItemData(Icons.folder_outlined, 'Documents', AppRoutes.documents),
      _NavItemData(Icons.person_search_outlined, 'Recrutement', AppRoutes.recruitment),
      _NavItemData(Icons.notifications_outlined, 'Notifications', AppRoutes.notifications, badge: unreadCount > 0 ? unreadCount.toString() : null),
      _NavItemData(Icons.chat_outlined, 'Messagerie', AppRoutes.messaging),
      _NavItemData(Icons.calendar_month_outlined, 'Agenda', AppRoutes.agenda),
      _NavItemData(Icons.bar_chart_outlined, 'Rapports', AppRoutes.reports),
      _NavItemData(Icons.manage_accounts_outlined, 'Utilisateurs', AppRoutes.users),
      _NavItemData(Icons.settings_outlined, 'Paramètres', AppRoutes.settings),
      _NavItemData(Icons.security_outlined, 'Sécurité', AppRoutes.security),
    ];

    // Réservé au Directeur (et Admin) : Paie, Primes, Sanctions
    const directorOnly = [
      AppRoutes.payroll,
      AppRoutes.bonuses,
      AppRoutes.sanctions,
    ];

    List<_NavItemData> filter(List<String> routes) =>
        all.where((i) => routes.contains(i.route)).toList();

    final groups = [
      _NavGroup(Icons.dashboard_outlined, 'Pilotage', [all[0]]),
      _NavGroup(Icons.groups_outlined, 'Personnel', filter([AppRoutes.employees, AppRoutes.departments, AppRoutes.positions, AppRoutes.contracts])),
      _NavGroup(Icons.fact_check_outlined, 'Suivi & Discipline', filter([AppRoutes.attendance, AppRoutes.leaves, AppRoutes.absences, AppRoutes.schedules, AppRoutes.sanctions])),
      _NavGroup(Icons.payments_outlined, 'Rémunération & Développement', filter([AppRoutes.payroll, AppRoutes.bonuses, AppRoutes.trainings, AppRoutes.evaluations, AppRoutes.documents, AppRoutes.recruitment])),
      _NavGroup(Icons.forum_outlined, 'Communication & Administration', filter([AppRoutes.notifications, AppRoutes.messaging, AppRoutes.agenda, AppRoutes.reports, AppRoutes.users, AppRoutes.settings, AppRoutes.security])),
    ];

    switch (role) {
      case AppConstants.roleEmployee:
        return groups
            .where((g) => g.items.any((i) => [
                  AppRoutes.dashboard, AppRoutes.leaves, AppRoutes.attendance,
                  AppRoutes.notifications, AppRoutes.messaging, AppRoutes.agenda,
                  AppRoutes.documents,
                ].contains(i.route)))
            .map((g) => _NavGroup(g.icon, g.title, g.items.where((i) => [
                  AppRoutes.dashboard, AppRoutes.leaves, AppRoutes.attendance,
                  AppRoutes.notifications, AppRoutes.messaging, AppRoutes.agenda,
                  AppRoutes.documents,
                ].contains(i.route)).toList()))
            .toList();

      case AppConstants.roleChefService:
        return groups
            .where((g) => g.items.any((i) => [
                  AppRoutes.dashboard, AppRoutes.employees, AppRoutes.attendance,
                  AppRoutes.leaves, AppRoutes.trainings, AppRoutes.documents,
                  AppRoutes.notifications, AppRoutes.messaging, AppRoutes.agenda,
                ].contains(i.route)))
            .map((g) => _NavGroup(g.icon, g.title, g.items.where((i) => [
                  AppRoutes.dashboard, AppRoutes.employees, AppRoutes.attendance,
                  AppRoutes.leaves, AppRoutes.trainings, AppRoutes.documents,
                  AppRoutes.notifications, AppRoutes.messaging, AppRoutes.agenda,
                ].contains(i.route)).toList()))
            .toList();

      case AppConstants.roleRH:
        return groups
            .where((g) => g.items.any((i) => !directorOnly.contains(i.route)))
            .map((g) => _NavGroup(g.icon, g.title, g.items.where((i) => !directorOnly.contains(i.route)).toList()))
            .toList();

      default:
        return groups;
    }
  }
}

class _NavGroup {
  final IconData icon;
  final String title;
  final List<_NavItemData> items;
  _NavGroup(this.icon, this.title, this.items);
}

class _NavGroupTile extends StatelessWidget {
  final _NavGroup group;
  final String currentLocation;
  const _NavGroupTile({required this.group, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(group.icon, color: Colors.white70, size: 18),
        title: Text(
          group.title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        childrenPadding: const EdgeInsets.only(left: 6),
        children: group.items
            .map((item) => _NavItem(
                  icon: item.icon,
                  label: item.label,
                  route: item.route,
                  isActive: currentLocation.startsWith(item.route),
                  badge: item.badge,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String route;
  final String? badge;
  _NavItemData(this.icon, this.label, this.route, {this.badge});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: isActive ? const Color(0xFFFFD700) : Colors.white70, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                       borderRadius: BorderRadius.circular(10),
                     ),
                     child: Text(badge!, style: const TextStyle(color: Color(0xFF8B0000), fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
               ],
             ),
           ),
         ),
       ),
     );
  }
}
