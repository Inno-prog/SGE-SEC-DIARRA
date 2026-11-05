import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

import 'package:dio/dio.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/models.dart';

class DocumentApiService extends BaseApiService {
  @override
  String get baseEndpoint => ApiConstants.documents;

  Future<Map<String, dynamic>> getDocuments({
    int? page,
    int? limit,
    String? employeeId,
    String? type,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (employeeId != null) query['employeeId'] = employeeId;
    if (type != null) query['type'] = type;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortOrder != null) query['sortOrder'] = sortOrder;
    return await get('', query: query);
  }

  Future<Map<String, dynamic>> getDocumentById(String id) async {
    return await get('/$id');
  }

  Future<Map<String, dynamic>> createDocument(DocumentModel document) async {
    return await post('', data: document.toJson());
  }

  Future<void> deleteDocument(String id) async {
    await delete('/$id');
  }

  Future<Map<String, dynamic>> uploadDocument(String employeeId, String type, String fileName, List<int> bytes) async {
    final formData = FormData.fromMap({
      'employeeId': employeeId,
      'type': type,
      'nom': fileName,
      'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: MediaType('application', 'pdf')),
    });
    final response = await apiClient.dio.post(
      '$baseEndpoint/upload',
      data: formData,
    );
    return response.data;
  }

  Future<Uint8List> downloadDocument(String id) async {
    final response = await apiClient.dio.get(
      '$baseEndpoint/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  String guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}