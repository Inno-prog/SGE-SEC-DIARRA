import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/auth/login_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/employees/employees_screen.dart';
import '../../screens/employees/employee_detail_screen.dart';
import '../../screens/employees/employee_form_screen.dart';
import '../../screens/departments/departments_screen.dart';
import '../../screens/positions/positions_screen.dart';
import '../../screens/contracts/contracts_screen.dart';
import '../../screens/contracts/contract_detail_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/leaves/leaves_screen.dart';
import '../../screens/absences/absences_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/agenda/agenda_screen.dart';
import '../../screens/reports/reports_screen.dart' hide SettingsScreen, SecurityScreen;
import '../../screens/settings/settings_screen.dart';
import '../../screens/security/security_screen.dart';
import '../../screens/schedules/schedules_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final initialLocation = ref.read(initialLocationProvider);

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 16),
              Text('Page introuvable', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Route: ${state.uri}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go(AppRoutes.dashboard), child: const Text('Retour au tableau de bord')),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;

      if (isLoading && state.matchedLocation != AppRoutes.login) {
        return AppRoutes.login;
      }

      if (!isLoggedIn && state.matchedLocation != AppRoutes.login) {
        return AppRoutes.login;
      }

      if (isLoggedIn && state.matchedLocation == AppRoutes.login) {
        final user = authState.value;
        if (user != null && user.mustChangePassword) {
          return AppRoutes.security;
        }
        final last = ref.read(lastLocationProvider);
        return last != AppRoutes.login ? last : AppRoutes.dashboard;
      }

      // Force redirect to security if mustChangePassword and not already there
      final user = authState.value;
      if (user != null &&
          user.mustChangePassword &&
          state.matchedLocation != AppRoutes.security) {
        return AppRoutes.security;
      }

      if (state.matchedLocation.startsWith('/')) {
        Future.microtask(() async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_location', state.matchedLocation);
        });
      }

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
          GoRoute(
            path: '/contracts/:id',
            builder: (_, state) => ContractDetailScreen(contractId: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.contracts, builder: (_, __) => const ContractsScreen()),
          GoRoute(path: AppRoutes.attendance, builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: AppRoutes.leaves, builder: (_, __) => const LeavesScreen()),
          GoRoute(path: AppRoutes.absences, builder: (_, __) => const AbsencesScreen()),
          GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersScreen()),
          GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.agenda, builder: (_, __) => const AgendaScreen()),
          GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
          GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
          GoRoute(path: AppRoutes.security, builder: (_, __) => const SecurityScreen()),
          GoRoute(path: AppRoutes.schedules, builder: (_, __) => const SchedulesScreen()),
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

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: _SideNav(currentLocation: location),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  final Widget child;
  const _NarrowLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(drawerKeyProvider);
    return Scaffold(
      key: key,
      drawer: Drawer(
        child: _SideNav(currentLocation: GoRouterState.of(context).matchedLocation),
      ),
      body: child,
    );
  }
}

class _SideNav extends ConsumerWidget {
  final String currentLocation;
  const _SideNav({required this.currentLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF580000), Color(0xFF580000)],
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

    if (role == AppConstants.roleAdmin || role == AppConstants.roleDirector) {
      return visible
          .map((g) => _NavGroupTile(group: g, currentLocation: currentLocation))
          .toList();
    }

    return visible.expand((g) => g.items).map((item) {
      final isActive = currentLocation.startsWith(item.route);
      return _NavItem(
        icon: item.icon,
        label: item.label,
        route: item.route,
        isActive: isActive,
      );
    }).toList();
  }

  List<_NavGroup> _getNavGroups(String role) {
    List<_NavItemData> filter(List<String> routes) => [
      _NavItemData(Icons.dashboard_outlined, 'Tableau de bord', AppRoutes.dashboard),
      _NavItemData(Icons.people_outline, 'Employés', AppRoutes.employees),
      _NavItemData(Icons.business_outlined, 'Départements', AppRoutes.departments),
      _NavItemData(Icons.work_outline, 'Postes', AppRoutes.positions),
      _NavItemData(Icons.description_outlined, 'Contrats', AppRoutes.contracts),
      _NavItemData(Icons.fingerprint, 'Présences', AppRoutes.attendance),
      _NavItemData(Icons.beach_access_outlined, 'Congés', AppRoutes.leaves),
      _NavItemData(Icons.event_busy_outlined, 'Absences', AppRoutes.absences),
      _NavItemData(Icons.schedule_outlined, 'Horaires', AppRoutes.schedules),
      _NavItemData(Icons.calendar_month_outlined, 'Agenda', AppRoutes.agenda),
      _NavItemData(Icons.bar_chart_outlined, 'Rapports', AppRoutes.reports),
      _NavItemData(Icons.manage_accounts_outlined, 'Utilisateurs', AppRoutes.users),
      _NavItemData(Icons.settings_outlined, 'Paramètres', AppRoutes.settings),
      _NavItemData(Icons.security_outlined, 'Sécurité', AppRoutes.security),
    ].where((i) => routes.contains(i.route)).toList();

    final groups = [
      _NavGroup(Icons.dashboard_outlined, 'Pilotage',
          filter([AppRoutes.dashboard])),
      _NavGroup(Icons.groups_outlined, 'Personnel',
          filter([AppRoutes.employees, AppRoutes.departments, AppRoutes.positions, AppRoutes.contracts])),
      _NavGroup(Icons.fact_check_outlined, 'Suivi',
          filter([AppRoutes.attendance, AppRoutes.leaves, AppRoutes.absences, AppRoutes.schedules])),
      _NavGroup(Icons.admin_panel_settings_outlined, 'Administration',
          filter([AppRoutes.agenda, AppRoutes.reports, AppRoutes.users, AppRoutes.settings, AppRoutes.security])),
    ];

    switch (role) {
      case AppConstants.roleEmployee:
        return [
          _NavGroup(Icons.dashboard_outlined, 'Pilotage', filter([AppRoutes.dashboard])),
          _NavGroup(Icons.fact_check_outlined, 'Suivi', filter([AppRoutes.attendance, AppRoutes.leaves])),
          _NavGroup(Icons.admin_panel_settings_outlined, 'Administration', filter([AppRoutes.agenda, AppRoutes.settings, AppRoutes.security])),
        ];
      case AppConstants.roleChefService:
        return [
          _NavGroup(Icons.dashboard_outlined, 'Pilotage', filter([AppRoutes.dashboard])),
          _NavGroup(Icons.groups_outlined, 'Personnel', filter([AppRoutes.employees])),
          _NavGroup(Icons.fact_check_outlined, 'Suivi', filter([AppRoutes.attendance, AppRoutes.leaves, AppRoutes.absences, AppRoutes.schedules])),
          _NavGroup(Icons.admin_panel_settings_outlined, 'Administration', filter([AppRoutes.agenda, AppRoutes.settings, AppRoutes.security])),
        ];
      case AppConstants.roleRH:
        return [
          _NavGroup(Icons.dashboard_outlined, 'Pilotage', filter([AppRoutes.dashboard])),
          _NavGroup(Icons.groups_outlined, 'Personnel', filter([AppRoutes.employees, AppRoutes.departments, AppRoutes.positions, AppRoutes.contracts])),
          _NavGroup(Icons.fact_check_outlined, 'Suivi', filter([AppRoutes.attendance, AppRoutes.leaves, AppRoutes.absences, AppRoutes.schedules])),
          _NavGroup(Icons.admin_panel_settings_outlined, 'Administration', filter([AppRoutes.agenda, AppRoutes.reports, AppRoutes.settings, AppRoutes.security])),
        ];
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

class _NavGroupTile extends StatefulWidget {
  final _NavGroup group;
  final String currentLocation;
  const _NavGroupTile({required this.group, required this.currentLocation});

  @override
  State<_NavGroupTile> createState() => _NavGroupTileState();
}

class _NavGroupTileState extends State<_NavGroupTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final hasActive = widget.group.items
        .any((i) => widget.currentLocation.startsWith(i.route));

    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(widget.group.icon,
                      color: hasActive ? const Color(0xFFFFD700) : Colors.white54,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.group.title.toUpperCase(),
                      style: TextStyle(
                        color: hasActive ? const Color(0xFFFFD700) : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Column(
                children: widget.group.items
                    .map((item) => _NavItem(
                          icon: item.icon,
                          label: item.label,
                          route: item.route,
                          isActive: widget.currentLocation.startsWith(item.route),
                        ))
                    .toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String route;
  _NavItemData(this.icon, this.label, this.route);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
