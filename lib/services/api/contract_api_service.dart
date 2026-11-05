import 'package:flutter/foundation.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class ContractApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.contracts;

  Future<Map<String, dynamic>> getContracts({
    int? page,
    int? limit,
    String? employeeId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (status != null) query['status'] = status;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    final response = await get('', query: query);
    debugPrint('API getContracts response: $response');
    return response;
  }

  Future<Map<String, dynamic>> getContractById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createContract(ContractModel contract) async {
    return await post('', data: contract.toJson());
  }

  Future<Map<String, dynamic>> updateContract(String id, ContractModel contract) async {
    return await patch('/$id', data: contract.toJson());
  }

  Future<void> deleteContract(String id) async {
    await delete('/$id');
  }

  Future<Map<String, dynamic>> getExpiringContracts() async {
    return await get('/expiring');
  }
}