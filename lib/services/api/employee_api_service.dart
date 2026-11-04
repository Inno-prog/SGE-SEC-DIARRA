import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/employee_model.dart';

class EmployeeApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.employees;

  // Get all employees with optional filters
  Future<Map<String, dynamic>> getEmployees({
    int? page,
    int? limit,
    String? search,
    String? departmentId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (search != null) query['search'] = search;
    if (departmentId != null) query['departmentId'] = departmentId;
    if (status != null) query['status'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  // Get employee stats
  Future<Map<String, dynamic>> getEmployeeStats() async {
    return await get(ApiConstants.employeeStats);
  }

  // Get birthdays this month
  Future<Map<String, dynamic>> getBirthdaysThisMonth() async {
    return await get(ApiConstants.employeeBirthdays);
  }

  // Generate matricule
  Future<Map<String, dynamic>> generateMatricule() async {
    return await get(ApiConstants.generateMatricule);
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    return await get('/$id');
  }

  // Create employee
  Future<Map<String, dynamic>> createEmployee(EmployeeModel employee) async {
    return await post('', data: employee.toJson());
  }

  // Update employee
  Future<Map<String, dynamic>> updateEmployee(String id, EmployeeModel employee) async {
    return await patch('/$id', data: employee.toJson());
  }

  // Delete employee
  Future<void> deleteEmployee(String id) async {
    await delete('/$id');
  }

  // Search employees
  Future<Map<String, dynamic>> searchEmployees(String query) async {
    return await get('', query: {'search': query});
  }
}