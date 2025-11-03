import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart'; // ✅ import cấu hình baseUrl

class ReportService {
  static final _storage = FlutterSecureStorage();

  // 🔧 Dùng baseUrl từ file cấu hình chung
  static String get reportUrl => '$baseUrl/reports';

  // 📦 Hàm lấy headers có token + username
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    final username = await _storage.read(key: 'username');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Username': username ?? '',
    };
  }

  /// 📤 Gửi báo cáo người dùng
  static Future<bool> reportUser({
    required int reportedAccountId,
    required String reason,
  }) async {
    final url = Uri.parse(reportUrl);
    final headers = await _getHeaders();
    final body = jsonEncode({
      'reportedAccountId': reportedAccountId,
      'reason': reason,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      print('✅ Báo cáo gửi thành công');
      return true;
    } else {
      print('❌ Lỗi khi gửi báo cáo: ${response.statusCode} - ${response.body}');
      return false;
    }
  }

  /// 📋 Lấy danh sách báo cáo chưa xử lý (chỉ ADMIN)
  static Future<List<Map<String, dynamic>>> getUnresolvedReports() async {
    final url = Uri.parse('$reportUrl/unresolved');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ Lỗi khi tải danh sách báo cáo: ${response.statusCode}');
      throw Exception('Không thể tải danh sách báo cáo');
    }
  }
}
