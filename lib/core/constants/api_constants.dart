class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String employees = '/employees';
  static const String departments = '/departments';
  static const String positions = '/positions';
  static const String contracts = '/contracts';
  static const String attendances = '/attendances';
  static const String leaves = '/leaves';
  static const String payrolls = '/payrolls';
  static const String bonuses = '/bonuses';
  static const String sanctions = '/sanctions';
  static const String trainings = '/trainings';
  static const String evaluations = '/evaluations';
  static const String documents = '/documents';
  static const String recruitments = '/recruitments';
  static const String notifications = '/notifications';
  static const String conversations = '/conversations';
  static const String agenda = '/agenda';
  static const String schedules = '/schedules';
  static const String audit = '/audit';
  static const String dashboard = '/dashboard';
static const String settings = '/settings';

  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String refresh = '/refresh';
  static const String logout = '/logout';
  static const String passwordReset = '/password/reset';
  static const String verify = '/verify';
  static const String profile = '/profile';
  static const String changePassword = '/password/change';

  // Employee endpoints
  static const String employeeStats = '/stats';
  static const String employeeBirthdays = '/birthdays';
  static const String generateMatricule = '/generate-matricule';

  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}