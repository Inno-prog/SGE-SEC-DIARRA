import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class PayrollApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.payrolls;

  Future<Map<String, dynamic>> getPayrolls({
    int? page,
    int? limit,
    int? mois,
    int? annee,
    String? employeeId,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (mois != null) query['mois'] = mois;
    if (annee != null) query['annee'] = annee;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (status != null) query['status'] = status;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getPayrollById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createPayroll(PayrollModel payroll) async {
    return await post('', data: payroll.toJson());
  }

  Future<Map<String, dynamic>> updatePayroll(String id, PayrollModel payroll) async {
    return await patch('/$id', data: payroll.toJson());
  }

  Future<void> deletePayroll(String id) async {
    await delete('/$id');
  }
}