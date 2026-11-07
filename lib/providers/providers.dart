import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api/api_service_provider.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../models/models.dart';
import '../models/department_model.dart';
import '../models/schedule_model.dart';
import '../core/constants/app_constants.dart';

// Re-export API service providers for screens to use
export '../services/api/api_service_provider.dart';

// ─── Services ────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─── Auth State ──────────────────────────────────────────────────────────────
// Use StateNotifier for mutable auth state
class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  AuthStateNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authService.currentUser;
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> updateUser(UserModel user) async {
    await _authService.updateUser(user);
    state = AsyncValue.data(user);
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthStateNotifier(ref.watch(authServiceProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});

final lastLocationProvider = StateProvider<String>((ref) => AppRoutes.dashboard);

final initialLocationProvider = Provider<String>((ref) {
  final last = ref.watch(lastLocationProvider);
  return last == AppRoutes.login ? AppRoutes.dashboard : last;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final drawerKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

final ensureEmployeeIdProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || (user.employeeId != null && user.employeeId!.isNotEmpty)) return;
  final auth = ref.read(authServiceProvider);
  try {
    await auth.updateUser(user.copyWith(employeeId: user.id));
  } catch (e) {
    debugPrint('ensureEmployeeId failed: $e');
  }
});

// ─── Dashboard ───────────────────────────────────────────────────────────────
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(dashboardApiServiceProvider);
  final response = await service.getStats();
  // Backend returns { stats: {...}, recentEmployees: [...], ... }
  // We need to extract the stats object
  final statsData = (response['stats'] ?? response['data'] ?? {}) as Map<String, dynamic>;
  // Map camelCase keys from backend to snake_case keys expected by frontend
  final mapped = <String, int>{
    'totalEmployes': (statsData['totalEmployes'] as num?)?.toInt() ?? 0,
    'presents_aujourd_hui': (statsData['presentsAujourdhui'] as num?)?.toInt() ?? 0,
    'en_conge': (statsData['enConge'] as num?)?.toInt() ?? 0,
    'conges_en_attente': (statsData['congesEnAttente'] as num?)?.toInt() ?? 0,
    'contrats_actifs': (statsData['contratsActifs'] as num?)?.toInt() ?? 0,
    'employes_actifs': (statsData['employesActifs'] as num?)?.toInt() ?? 0,
  };
  return mapped;
});

final birthdaysProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  final service = ref.watch(employeeApiServiceProvider);
  final response = await service.getBirthdaysThisMonth();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => EmployeeModel.fromJson(e)).toList();
});

// ─── Employees ───────────────────────────────────────────────────────────────
final employeesProvider = FutureProvider.family<List<EmployeeModel>, Map<String, String?>>((ref, filters) async {
  final service = ref.watch(employeeApiServiceProvider);
  final response = await service.getEmployees(
    departmentId: filters['departementId'],
    status: filters['statut'],
  );
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => EmployeeModel.fromJson(e)).toList();
});

final allEmployeesProvider = FutureProvider<List<EmployeeModel>>((ref) async {
  final service = ref.watch(employeeApiServiceProvider);
  final response = await service.getEmployees();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => EmployeeModel.fromJson(e)).toList();
});

final employeeSearchProvider = StateProvider<String>((ref) => '');

final departmentFilterProvider = StateProvider<String?>((ref) => null);

final filteredEmployeesProvider = Provider<AsyncValue<List<EmployeeModel>>>((ref) {
  final query = ref.watch(employeeSearchProvider).toLowerCase();
  final deptId = ref.watch(departmentFilterProvider);
  final employees = ref.watch(allEmployeesProvider);
  return employees.whenData(
    (list) {
      var filtered = list;
      if (deptId != null) {
        filtered = filtered.where((e) => e.departementId == deptId).toList();
      }
      if (query.isEmpty) return filtered;
      return filtered.where((e) =>
          e.fullName.toLowerCase().contains(query) ||
          e.matricule.toLowerCase().contains(query) ||
          e.departementNom.toLowerCase().contains(query) ||
          e.poste.toLowerCase().contains(query)).toList();
    },
  );
});

// ─── Departments ─────────────────────────────────────────────────────────────
final departmentsProvider = FutureProvider<List<DepartmentModel>>((ref) async {
  final service = ref.watch(departmentApiServiceProvider);
  final response = await service.getDepartments();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => DepartmentModel.fromJson(e)).toList();
});

/// Department detail with employees and responsable
final departmentDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final service = ref.watch(departmentApiServiceProvider);
  final response = await service.getDepartmentById(id);
  return response['department'] ?? response['data'] ?? {};
});

// ─── Positions ───────────────────────────────────────────────────────────────
final positionsProvider = FutureProvider<List<PositionModel>>((ref) async {
  final service = ref.watch(positionApiServiceProvider);
  final response = await service.getPositions();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => PositionModel.fromJson(e)).toList();
});

/// Positions with department names populated by joining with departments list
final positionsWithDepartmentsProvider = FutureProvider<List<PositionModel>>((ref) async {
  final positions = await ref.watch(positionsProvider.future);
  final departments = await ref.watch(departmentsProvider.future);

  // Create a map for quick lookup
  final deptMap = {for (var d in departments) d.id: d.nom};

  // Merge department names into positions
  return positions.map((p) {
    final deptNom = p.departementId != null ? deptMap[p.departementId!] : null;
    return PositionModel(
      id: p.id,
      titre: p.titre,
      description: p.description,
      departementId: p.departementId,
      departementNom: deptNom ?? p.departementNom, // fallback to API value if exists
      salaireMini: p.salaireMini,
      salaireMaxi: p.salaireMaxi,
      createdAt: p.createdAt,
    );
  }).toList();
});

// ─── Contracts ───────────────────────────────────────────────────────────────
final contractsProvider = FutureProvider.family<List<ContractModel>, String?>((ref, employeeId) async {
  final service = ref.watch(contractApiServiceProvider);
  final response = await service.getContracts(employeeId: employeeId);
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => ContractModel.fromJson(e)).toList();
});

final expiringContractsProvider = Provider<AsyncValue<List<ContractModel>>>((ref) {
  return ref.watch(contractsProvider(null)).whenData(
        (list) => list.where((c) => c.isExpiringSoon).toList(),
      );
});

final contractExpiryNotificationsProvider = Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);
  final notifsProvider = ref.watch(notificationsProvider(user.id));
  return notifsProvider.whenData(
    (list) => list.where((n) => n.type == 'contract_expiry' && !n.isRead).toList(),
  );
});

final syncContractExpiryNotificationsProvider = FutureProvider<void>((ref) async {
  // Notifications are now fetched per-user from the API
});

// ─── Attendance ──────────────────────────────────────────────────────────────
class AttendanceParams {
  final DateTime? date;
  final String? employeeId;
  const AttendanceParams({this.date, this.employeeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceParams &&
          other.date == date &&
          other.employeeId == employeeId;

  @override
  int get hashCode => date.hashCode ^ employeeId.hashCode;
}

final selectedAttendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final attendanceProvider = FutureProvider.family<List<AttendanceModel>, AttendanceParams>((ref, params) async {
  final service = ref.watch(attendanceApiServiceProvider);
  String? dateStr;
  if (params.date != null) {
    // Backend expects date at start of day (00:00:00.000Z) for date filtering
    final dateOnly = DateTime(params.date!.year, params.date!.month, params.date!.day);
    dateStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(dateOnly.toUtc());
  }
  final response = await service.getAttendances(
    date: dateStr,
    employeeId: params.employeeId,
  );
  // Handle different response formats: data, attendances, or direct array
  final List<dynamic> data = response['data'] ?? response['attendances'] ?? response['items'] ?? [];
  return data.map((e) => AttendanceModel.fromJson(e)).toList();
});

final todayAttendanceProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final service = ref.watch(attendanceApiServiceProvider);
  final now = DateTime.now();
  final dateOnly = DateTime(now.year, now.month, now.day);
  final dateStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(dateOnly.toUtc());
  final response = await service.getAttendances(date: dateStr);
  // Handle different response formats
  final List<dynamic> data = response['data'] ?? response['attendances'] ?? response['items'] ?? [];
  return data.map((e) => AttendanceModel.fromJson(e)).toList();
});

// Fetch all attendances (for absences screen)
final allAttendancesProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final service = ref.watch(attendanceApiServiceProvider);
  final response = await service.getAttendances();
  // Handle different response formats
  final List<dynamic> data = response['data'] ?? response['attendances'] ?? response['items'] ?? [];
  return data.map((e) => AttendanceModel.fromJson(e)).toList();
});

class LeaveParams {
  final String? employeeId;
  final String? status;
  const LeaveParams({this.employeeId, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveParams &&
          other.employeeId == employeeId &&
          other.status == status;

  @override
  int get hashCode => employeeId.hashCode ^ status.hashCode;
}

// ─── Leaves ──────────────────────────────────────────────────────────────────
final leavesProvider = FutureProvider.family<List<LeaveModel>, LeaveParams>((ref, params) async {
  final service = ref.watch(leaveApiServiceProvider);
  final response = await service.getLeaves(
    employeeId: params.employeeId,
    status: params.status,
  );
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => LeaveModel.fromJson(e)).toList();
});

final pendingLeavesProvider = FutureProvider<List<LeaveModel>>((ref) async {
  final service = ref.watch(leaveApiServiceProvider);
  final response = await service.getLeaves(status: 'en_attente');
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => LeaveModel.fromJson(e)).toList();
});

// ─── Bonuses ────────────────────────────────────────────────
class BonusParams {
  final String? employeeId;
  final String? status;
  const BonusParams({this.employeeId, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BonusParams &&
          other.employeeId == employeeId &&
          other.status == status;

  @override
  int get hashCode => employeeId.hashCode ^ status.hashCode;
}

final bonusesProvider = FutureProvider.family<List<BonusModel>, BonusParams>((ref, params) async {
  final service = ref.watch(bonusApiServiceProvider);
  final response = await service.getBonuses(
    employeeId: params.employeeId,
  );
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => BonusModel.fromJson(e)).toList();
});

final allBonusesProvider = FutureProvider<List<BonusModel>>((ref) async {
  final service = ref.watch(bonusApiServiceProvider);
  final response = await service.getBonuses();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => BonusModel.fromJson(e)).toList();
});

// ─── Payroll ───────────────────────────────────────────────────────────────────
class PayrollParams {
  final int? month;
  final int? year;
  final String? employeeId;
  final String? status;
  const PayrollParams({this.month, this.year, this.employeeId, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollParams &&
          other.month == month &&
          other.year == year &&
          other.employeeId == employeeId &&
          other.status == status;

  @override
  int get hashCode => month.hashCode ^ year.hashCode ^ employeeId.hashCode ^ status.hashCode;
}

final payrollProvider = FutureProvider.family<List<PayrollModel>, PayrollParams>((ref, params) async {
  final service = ref.watch(payrollApiServiceProvider);
  final response = await service.getPayrolls(
    mois: params.month,
    annee: params.year,
    employeeId: params.employeeId,
    status: params.status,
  );
  final List<dynamic> data = response['data'] ?? response['payrolls'] ?? response['items'] ?? [];
  final list = data.map((e) => PayrollModel.fromJson(e)).toList();
  list.sort((a, b) {
    final byYear = b.annee.compareTo(a.annee);
    return byYear != 0 ? byYear : b.mois.compareTo(a.mois);
  });
  return list;
});

final allPayrollsProvider = FutureProvider<List<PayrollModel>>((ref) async {
  final service = ref.watch(payrollApiServiceProvider);
  final response = await service.getPayrolls();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => PayrollModel.fromJson(e)).toList();
});

// ─── Trainings ───────────────────────────────────────────────────────────────
final trainingsProvider = FutureProvider.family<List<TrainingModel>, String?>((ref, employeeId) async {
  final service = ref.watch(trainingApiServiceProvider);
  final response = await service.getTrainings(employeeId: employeeId);
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => TrainingModel.fromJson(e)).toList();
});

// ─── Recruitment ─────────────────────────────────────────────────────────────
final recruitmentProvider = FutureProvider<List<RecruitmentModel>>((ref) async {
  final service = ref.watch(recruitmentApiServiceProvider);
  final response = await service.getRecruitments();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => RecruitmentModel.fromJson(e)).toList();
});

// ─── Notifications ───────────────────────────────────────────────────────────
// API gets notifications for current authenticated user (ignores userId param, uses JWT)
final notificationsProvider = FutureProvider.family<List<NotificationModel>, String?>((ref, userId) async {
  final service = ref.watch(notificationApiServiceProvider);
  final response = await service.getNotifications();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => NotificationModel.fromJson(e)).toList();
});

final unreadNotificationsCountProvider = Provider.family<int, String?>((ref, userId) {
  final notifs = ref.watch(notificationsProvider(userId));
  return notifs.when(
        data: (list) => list.where((n) => !n.isRead).length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

// ─── Messages ────────────────────────────────────────────────────────────────
// Conversations are returned as List<Map<String, dynamic>> from the API (uses JWT)
final conversationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, userId) async {
  final service = ref.watch(conversationApiServiceProvider);
  final response = await service.getConversations();
  final List<dynamic> data = response['data'] ?? [];
  return data.cast<Map<String, dynamic>>();
});

final messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, conversationId) async {
  final service = ref.watch(conversationApiServiceProvider);
  final response = await service.getMessages(conversationId);
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => MessageModel.fromJson(e)).toList();
});

// ─── Agenda ──────────────────────────────────────────────────────────────────
final agendaProvider = FutureProvider<List<AgendaModel>>((ref) async {
  final service = ref.watch(agendaApiServiceProvider);
  final now = DateTime.now();
  final response = await service.getAgendaEvents(
    from: DateTime(now.year, now.month, 1),
    to: DateTime(now.year, now.month + 2, 0),
  );
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => AgendaModel.fromJson(e)).toList();
});

// ─── Schedules ────────────────────────────────────────────────────────────────
final schedulesProvider = FutureProvider<List<ScheduleModel>>((ref) async {
  final service = ref.watch(scheduleApiServiceProvider);
  final response = await service.getSchedules();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => ScheduleModel.fromJson(e)).toList();
});

// ─── Audit Logs ──────────────────────────────────────────────────────────────
final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final service = ref.watch(auditApiServiceProvider);
  final response = await service.getAuditLogs();
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => AuditLogModel.fromJson(e)).toList();
});

// ─── Users ───────────────────────────────────────────────────────────────────
final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getAllUsers();
});

/// Users for responsable dropdown (active users only)
final usersForResponsableProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.watch(userApiServiceProvider);
  final response = await service.getUsers(limit: 100);
  final List<dynamic> data = response['data'] ?? [];
  return data
      .map((e) => UserModel.fromJson(e))
      .where((u) => u.isActive)
      .toList();
});

// ─── Contract Documents ──────────────────────────────────────────────────────
final contractDocumentsProvider = FutureProvider.family<List<DocumentModel>, List<String>>((ref, docIds) async {
  if (docIds.isEmpty) return [];
  final service = ref.watch(documentApiServiceProvider);
  final List<DocumentModel> documents = [];
  for (final id in docIds) {
    try {
      final response = await service.getDocumentById(id);
      // API returns document under 'document' key, not 'data'
      final docData = response['document'] ?? response['data'];
      if (docData != null) {
        documents.add(DocumentModel.fromJson(docData));
      }
    } catch (e) {
      debugPrint('Failed to load document $id: $e');
    }
  }
  return documents;
});

// ─── Employee Documents ──────────────────────────────────────────────────────
// Fetch documents for an employee by type
final employeeDocumentsProvider = FutureProvider.family<List<DocumentModel>, ({String employeeId, String type})>((ref, params) async {
  final service = ref.watch(documentApiServiceProvider);
  final response = await service.getDocuments(
    employeeId: params.employeeId,
    type: params.type,
  );
  // Handle different response formats
  final List<dynamic> data = response['data'] ?? response['documents'] ?? response['items'] ?? [];
  return data.map((e) => DocumentModel.fromJson(e)).toList();
});

// ─── Settings ───────────────────────────────────────────────────────────────────
/// Company name for app title customization
final companyNameProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(settingsApiServiceProvider);
  try {
    final response = await service.getSettings();
    return response['companyName'] ?? response['company_name'];
  } catch (e) {
    debugPrint('Failed to load company name: $e');
    return null;
  }
});

/// Full app name with company name (e.g., "SGE MyCompany")
final appNameProvider = Provider<String>((ref) {
  final companyName = ref.watch(companyNameProvider).value;
  return AppConstants.getAppName(companyName: companyName);
});