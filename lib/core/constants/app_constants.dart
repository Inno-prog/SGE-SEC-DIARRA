class AppConstants {
  static const String appName = 'SGE Secdiarra';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String colUsers = 'users';
  static const String colEmployees = 'employees';
  static const String colDepartments = 'departments';
  static const String colPositions = 'positions';
  static const String colContracts = 'contracts';
  static const String colAttendance = 'attendance';
  static const String colLeaves = 'leaves';
  static const String colAbsences = 'absences';
  static const String colSchedules = 'schedules';
  static const String colPayroll = 'payroll';
  static const String colBonuses = 'bonuses';
  static const String colSanctions = 'sanctions';
  static const String colTrainings = 'trainings';
  static const String colEvaluations = 'evaluations';
  static const String colDocuments = 'documents';
  static const String colRecruitment = 'recruitment';
  static const String colNotifications = 'notifications';
  static const String colMessages = 'messages';
  static const String colConversations = 'conversations';
  static const String colAgenda = 'agenda';
  static const String colAuditLogs = 'audit_logs';
  static const String colSettings = 'settings';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleRH = 'rh';
  static const String roleDirector = 'director';
  static const String roleChefService = 'chef_service';
  static const String roleEmployee = 'employee';

  // Employee status
  static const String statusActive = 'actif';
  static const String statusSuspended = 'suspendu';
  static const String statusResigned = 'demissionnaire';

  // Contract types
  static const String contractCDI = 'CDI';
  static const String contractCDD = 'CDD';
  static const String contractStage = 'Stage';
  static const String contractConsultant = 'Consultant';
  static const String contractPrestataire = 'Prestataire';

  // Leave types
  static const String leaveAnnual = 'Congé annuel';
  static const String leaveSick = 'Congé maladie';
  static const String leaveMaternity = 'Congé maternité';
  static const String leaveExceptional = 'Congé exceptionnel';

  // Leave status
  static const String leavePending = 'en_attente';
  static const String leaveApproved = 'approuvé';
  static const String leaveRejected = 'refusé';

  // Sanction types
  static const String sanctionWarning = 'Avertissement';
  static const String sanctionBlame = 'Blâme';
  static const String sanctionSuspension = 'Suspension';
  static const String sanctionLayoff = 'Mise à pied';

  // Pagination
  static const int pageSize = 20;

  // Storage paths
  static const String storageEmployeePhotos = 'employee_photos';
  static const String storageDocuments = 'documents';
  static const String storageContracts = 'contracts';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String employees = '/employees';
  static const String employeeDetail = '/employees/:id';
  static const String employeeAdd = '/employees/add';
  static const String departments = '/departments';
  static const String positions = '/positions';
  static const String contracts = '/contracts';
  static const String attendance = '/attendance';
  static const String leaves = '/leaves';
  static const String absences = '/absences';
  static const String schedules = '/schedules';
  static const String payroll = '/payroll';
  static const String bonuses = '/bonuses';
  static const String sanctions = '/sanctions';
  static const String trainings = '/trainings';
  static const String evaluations = '/evaluations';
  static const String documents = '/documents';
  static const String recruitment = '/recruitment';
  static const String users = '/users';
  static const String notifications = '/notifications';
  static const String messaging = '/messaging';
  static const String agenda = '/agenda';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String security = '/security';
  static const String profile = '/profile';
}
