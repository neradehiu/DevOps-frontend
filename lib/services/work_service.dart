import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';

class WorkService {
  static final _storage = FlutterSecureStorage();

  // ✅ Đường dẫn API công việc
  static String get _endpoint => '$baseUrl/works-posted';

  // 🔒 Lấy headers có token, username, role
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập lại.');
    }

    final decodedToken = JwtDecoder.decode(token);
    final username = decodedToken['sub'] ?? '';
    final role = decodedToken['role'] ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Username': username,
      'X-Role': role,
    };
  }

  /// 🟢 Tạo công việc mới
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
      Uri.parse(_endpoint),
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

    print('[DEBUG] ➕ Create work: ${response.statusCode}');
    print('[DEBUG] Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('❌ Tạo công việc thất bại (${response.statusCode})');
    }
  }

  /// 🟡 Lấy danh sách công việc
  static Future<List<Map<String, dynamic>>> getAllWorks() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(_endpoint), headers: headers);

    print('[DEBUG] 📄 Get works: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((e) => {
        'id': e['id'],
        'position': e['position'],
        'descriptionWork': e['descriptionWork'],
        'salary': e['salary'],
        'companyId': e['companyId'],
        'company': e['companyName'],
        'createdByUsername': e['createdByUsername'],
      }).toList();
    } else {
      throw Exception('❌ Không thể tải danh sách công việc (${response.statusCode})');
    }
  }

  /// 🟠 Cập nhật công việc
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
      Uri.parse('$_endpoint/$id'),
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

    print('[DEBUG] ✏️ Update work: ${response.statusCode}');
    print('[DEBUG] Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('❌ Không thể cập nhật công việc (${response.statusCode})');
    }
  }

  /// 🔴 Xóa công việc
  static Future<void> deleteWork(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(Uri.parse('$_endpoint/$id'), headers: headers);

    print('[DEBUG] 🗑️ Delete work: ${response.statusCode}');

    if (response.statusCode != 204) {
      throw Exception('❌ Không thể xóa công việc (${response.statusCode})');
    }
  }
}
