import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../models/models.dart';
import '../models/department_model.dart';
import '../models/schedule_model.dart';
import '../core/constants/app_constants.dart';

// ─── Services ────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// ─── Auth State ──────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  await for (final user in authService.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      yield await authService.getUserById(user.uid);
    }
  }
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});

final lastLocationProvider = StateProvider<String>((ref) => AppRoutes.dashboard);

final initialLocationProvider = Provider<String>((ref) {
  return AppRoutes.login;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── Dashboard ───────────────────────────────────────────────────────────────
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(firestoreServiceProvider).getDashboardStats();
});

final birthdaysProvider = FutureProvider<List<EmployeeModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getBirthdaysThisMonth();
});

// ─── Employees ───────────────────────────────────────────────────────────────
final employeesProvider = StreamProvider.family<List<EmployeeModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(firestoreServiceProvider).watchEmployees(
        departementId: filters['departementId'],
        statut: filters['statut'],
      );
});

final allEmployeesProvider = StreamProvider<List<EmployeeModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchEmployees();
});

final employeeSearchProvider = StateProvider<String>((ref) => '');

final filteredEmployeesProvider = Provider<AsyncValue<List<EmployeeModel>>>((ref) {
  final query = ref.watch(employeeSearchProvider).toLowerCase();
  final employees = ref.watch(allEmployeesProvider);
  if (query.isEmpty) return employees;
  return employees.whenData(
    (list) => list.where((e) =>
        e.fullName.toLowerCase().contains(query) ||
        e.matricule.toLowerCase().contains(query) ||
        e.departementNom.toLowerCase().contains(query) ||
        e.poste.toLowerCase().contains(query)).toList(),
  );
});

// ─── Departments ─────────────────────────────────────────────────────────────
final departmentsProvider = StreamProvider<List<DepartmentModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchDepartments();
});

// ─── Positions ───────────────────────────────────────────────────────────────
final positionsProvider = StreamProvider<List<PositionModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchPositions();
});

// ─── Contracts ───────────────────────────────────────────────────────────────
final contractsProvider = StreamProvider.family<List<ContractModel>, String?>((ref, employeeId) {
  return ref.watch(firestoreServiceProvider).watchContracts(employeeId: employeeId);
});

final expiringContractsProvider = Provider<AsyncValue<List<ContractModel>>>((ref) {
  return ref.watch(contractsProvider(null)).whenData(
        (list) => list.where((c) => c.isExpiringSoon).toList(),
      );
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

final attendanceProvider = StreamProvider.family<List<AttendanceModel>, AttendanceParams>((ref, params) {
  return ref.watch(firestoreServiceProvider).watchAttendance(
        date: params.date,
        employeeId: params.employeeId,
      );
});

final todayAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAttendance(date: DateTime.now());
});

class LeaveParams {
  final String? employeeId;
  final String? statut;
  const LeaveParams({this.employeeId, this.statut});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveParams &&
          other.employeeId == employeeId &&
          other.statut == statut;

  @override
  int get hashCode => employeeId.hashCode ^ statut.hashCode;
}

// ─── Leaves ──────────────────────────────────────────────────────────────────
final leavesProvider = StreamProvider.family<List<LeaveModel>, LeaveParams>((ref, params) {
  return ref.watch(firestoreServiceProvider).watchLeaves(
        employeeId: params.employeeId,
        statut: params.statut,
      );
});

final pendingLeavesProvider = StreamProvider<List<LeaveModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchLeaves(statut: 'en_attente');
});

// ─── Payroll ─────────────────────────────────────────────────────────────────
class PayrollParams {
  final int? mois;
  final int? annee;
  final String? employeeId;
  const PayrollParams({this.mois, this.annee, this.employeeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollParams &&
          other.mois == mois &&
          other.annee == annee &&
          other.employeeId == employeeId;

  @override
  int get hashCode => mois.hashCode ^ annee.hashCode ^ employeeId.hashCode;
}

final selectedPayrollMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final payrollProvider = StreamProvider.family<List<PayrollModel>, PayrollParams>((ref, params) {
  return ref.watch(firestoreServiceProvider).watchPayroll(
        mois: params.mois,
        annee: params.annee,
        employeeId: params.employeeId,
      );
});

// ─── Bonuses ────────────────────────────────────────────────
class BonusParams {
  final String? employeeId;
  final String? statut;
  const BonusParams({this.employeeId, this.statut});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BonusParams &&
          other.employeeId == employeeId &&
          other.statut == statut;

  @override
  int get hashCode => employeeId.hashCode ^ statut.hashCode;
}

final bonusesProvider = StreamProvider.family<List<BonusModel>, BonusParams>((ref, params) {
  return ref.watch(firestoreServiceProvider).watchBonuses(
        employeeId: params.employeeId,
      );
});

final allBonusesProvider = StreamProvider<List<BonusModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchBonuses();
});

// ─── Sanctions ───────────────────────────────────────────────────────────────
final sanctionsProvider = StreamProvider.family<List<SanctionModel>, String?>((ref, employeeId) {
  return ref.watch(firestoreServiceProvider).watchSanctions(employeeId: employeeId);
});

// ─── Trainings ───────────────────────────────────────────────────────────────
final trainingsProvider = StreamProvider.family<List<TrainingModel>, String?>((ref, employeeId) {
  return ref.watch(firestoreServiceProvider).watchTrainings(employeeId: employeeId);
});

// ─── Evaluations ─────────────────────────────────────────────────────────────
final evaluationsProvider = StreamProvider.family<List<EvaluationModel>, String?>((ref, employeeId) {
  return ref.watch(firestoreServiceProvider).watchEvaluations(employeeId: employeeId);
});

// ─── Documents ───────────────────────────────────────────────────────────────
final documentsProvider = StreamProvider.family<List<DocumentModel>, String?>((ref, employeeId) {
  return ref.watch(firestoreServiceProvider).watchDocuments(employeeId: employeeId);
});

// ─── Recruitment ─────────────────────────────────────────────────────────────
final recruitmentProvider = StreamProvider<List<RecruitmentModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchRecruitment();
});

// ─── Notifications ───────────────────────────────────────────────────────────
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchNotifications(user.id);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).when(
        data: (list) => list.where((n) => !n.isRead).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

// ─── Messages ────────────────────────────────────────────────────────────────
final conversationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchConversations(user.id);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ref.watch(firestoreServiceProvider).watchMessages(conversationId);
});

// ─── Agenda ──────────────────────────────────────────────────────────────────
final agendaProvider = StreamProvider<List<AgendaModel>>((ref) {
  final now = DateTime.now();
  return ref.watch(firestoreServiceProvider).watchAgenda(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 2, 0),
      );
});

// ─── Schedules ────────────────────────────────────────────────────────────────
final schedulesProvider = StreamProvider<List<ScheduleModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchSchedules();
});

// ─── Audit Logs ──────────────────────────────────────────────────────────────
final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAuditLogs();
});

// ─── Users ───────────────────────────────────────────────────────────────────
final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(authServiceProvider).watchAllUsers();
});
