import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class WorkService {
  static final _storage = FlutterSecureStorage();

  // 🔧 BASE_URL động theo môi trường
  static const String baseHost = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://165.22.55.126:8080',
  );
  static String get baseUrl => '$baseHost/api/works-posted';

  // Lấy headers chứa token & role
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('Token không tồn tại. Vui lòng đăng nhập.');

    final decodedToken = JwtDecoder.decode(token);
    final username = decodedToken['sub'];
    final role = decodedToken['role'];

    print('[DEBUG] Token: $token');
    print('[DEBUG] Username: $username');
    print('[DEBUG] Role: $role');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Username': username,
      'X-Role': role,
    };
  }

  /// Tạo công việc mới
  static Future<Map<String, dynamic>> createWork({
    required String position,
    required String descriptionWork,
    required int maxAccepted,
    required int maxReceiver,
    required double salary,
    required int companyId,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'position': position,
        'descriptionWork': descriptionWork,
        'maxAccepted': maxAccepted,
        'maxReceiver': maxReceiver,
        'salary': salary,
        'companyId': companyId,
      }),
    );

    print('[DEBUG] Create work response: ${response.statusCode}');
    print('[DEBUG] Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Tạo công việc thất bại: ${response.statusCode}');
    }
  }

  /// Lấy danh sách tất cả công việc
  static Future<List<Map<String, dynamic>>> getAllWorks() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    print('[DEBUG] Get works response: ${response.statusCode}');
    print('[DEBUG] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id'],
          'position': e['position'],
          'descriptionWork': e['descriptionWork'],
          'salary': e['salary'],
          'companyId': e['companyId'],
          'company': e['companyName'],
          'createdByUsername': e['createdByUsername']
        };
      }).toList();
    } else {
      throw Exception('Không thể tải danh sách công việc: ${response.statusCode}');
    }
  }

  /// Cập nhật công việc
  static Future<Map<String, dynamic>> updateWork({
    required int id,
    required String position,
    required String descriptionWork,
    required int maxAccepted,
    required int maxReceiver,
    required double salary,
    required int companyId,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'position': position,
        'descriptionWork': descriptionWork,
        'maxAccepted': maxAccepted,
        'maxReceiver': maxReceiver,
        'salary': salary,
        'companyId': companyId,
      }),
    );

    print('[DEBUG] Update work response: ${response.statusCode}');
    print('[DEBUG] Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Bạn không có quyền cập nhật công việc này: ${response.statusCode}');
    }
  }

  /// Xóa công việc
  static Future<void> deleteWork(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);

    print('[DEBUG] Delete work response: ${response.statusCode}');

    if (response.statusCode != 204) {
      throw Exception('Bạn không có quyền xóa công việc này: ${response.statusCode}');
    }
  }
}
