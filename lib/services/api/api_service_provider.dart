import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_api_service.dart';
import 'employee_api_service.dart';
import 'department_api_service.dart';
import 'leave_api_service.dart';
import 'attendance_api_service.dart';
import 'contract_api_service.dart';
import 'payroll_api_service.dart';
import 'bonus_api_service.dart';
import 'sanction_api_service.dart';
import 'training_api_service.dart';
import 'evaluation_api_service.dart';
import 'document_api_service.dart';
import 'recruitment_api_service.dart';
import 'notification_api_service.dart';
import 'conversation_api_service.dart';
import 'agenda_api_service.dart';
import 'schedule_api_service.dart';
import 'audit_api_service.dart';
import 'dashboard_api_service.dart';
import 'position_api_service.dart';
import 'user_api_service.dart';
import 'settings_api_service.dart';

// Auth API Service Provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final service = AuthApiService();
  return service;
});

// Employee API Service Provider
final employeeApiServiceProvider = Provider<EmployeeApiService>((ref) {
  return EmployeeApiService();
});

// Department API Service Provider
final departmentApiServiceProvider = Provider<DepartmentApiService>((ref) {
  return DepartmentApiService();
});

// Leave API Service Provider
final leaveApiServiceProvider = Provider<LeaveApiService>((ref) {
  return LeaveApiService();
});

// Attendance API Service Provider
final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService();
});

// Contract API Service Provider
final contractApiServiceProvider = Provider<ContractApiService>((ref) {
  return ContractApiService();
});

// Payroll API Service Provider
final payrollApiServiceProvider = Provider<PayrollApiService>((ref) {
  return PayrollApiService();
});

// Bonus API Service Provider
final bonusApiServiceProvider = Provider<BonusApiService>((ref) {
  return BonusApiService();
});

// Sanction API Service Provider
final sanctionApiServiceProvider = Provider<SanctionApiService>((ref) {
  return SanctionApiService();
});

// Training API Service Provider
final trainingApiServiceProvider = Provider<TrainingApiService>((ref) {
  return TrainingApiService();
});

// Evaluation API Service Provider
final evaluationApiServiceProvider = Provider<EvaluationApiService>((ref) {
  return EvaluationApiService();
});

// Document API Service Provider
final documentApiServiceProvider = Provider<DocumentApiService>((ref) {
  return DocumentApiService();
});

// Recruitment API Service Provider
final recruitmentApiServiceProvider = Provider<RecruitmentApiService>((ref) {
  return RecruitmentApiService();
});

// Notification API Service Provider
final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService();
});

// Conversation API Service Provider
final conversationApiServiceProvider = Provider<ConversationApiService>((ref) {
  return ConversationApiService();
});

// Agenda API Service Provider
final agendaApiServiceProvider = Provider<AgendaApiService>((ref) {
  return AgendaApiService();
});

// Schedule API Service Provider
final scheduleApiServiceProvider = Provider<ScheduleApiService>((ref) {
  return ScheduleApiService();
});

// Audit API Service Provider
final auditApiServiceProvider = Provider<AuditApiService>((ref) {
  return AuditApiService();
});

// Dashboard API Service Provider
final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService();
});

// Position API Service Provider
final positionApiServiceProvider = Provider<PositionApiService>((ref) {
  return PositionApiService();
});

// Settings API Service Provider
final settingsApiServiceProvider = Provider<SettingsApiService>((ref) {
  return SettingsApiService();
});

// User API Service Provider
final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService();
});