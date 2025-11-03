import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class WorkAcceptanceService {
  static final _storage = FlutterSecureStorage();

  // 🔗 Dùng baseUrl từ config chung
  static String get workUrl => '$baseUrl/works';

  // 🧾 Lấy token + thông tin người dùng
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    final username = await _storage.read(key: 'username');
    final role = await _storage.read(key: 'role');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Username': username ?? '',
      'X-Role': role ?? '',
    };
  }

  /// ✅ 1. Nhận việc
  static Future<bool> acceptWork(
      BuildContext context, int workId, int accountId) async {
    final url = Uri.parse('$workUrl/$workId/acceptances');
    final headers = await _getHeaders();
    final body = jsonEncode({'workPostedId': workId, 'accountId': accountId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 401 &&
        response.body.contains("Tài khoản đã bị khóa")) {
      await _storage.deleteAll(); // Xóa token và quay lại login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return false;
    }

    return response.statusCode == 200;
  }

  /// ✅ 2. Lấy danh sách người đã nhận việc
  static Future<List<dynamic>> getAcceptancesByWork(int workId) async {
    final url = Uri.parse('$workUrl/$workId/acceptances');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tải danh sách người nhận việc');
    }
  }

  /// ✅ 3. Lấy danh sách người dùng theo trạng thái (accepted/cancelled/completed)
  static Future<List<dynamic>> getAcceptedJobsByStatus(
      int workId, int accountId, String status) async {
    final url = Uri.parse(
        '$workUrl/$workId/acceptances/account/$accountId/status/$status');
    final headers = await _getHeaders();

    print('🔍 [DEBUG] API: $url');
    final response = await http.get(url, headers: headers);
    print('📥 Status: ${response.statusCode}');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy công việc theo trạng thái');
    }
  }

  /// ✅ 4. Cập nhật trạng thái người nhận việc
  static Future<bool> updateAcceptanceStatus(
      int workId, int acceptanceId, String newStatus) async {
    final url = Uri.parse('$workUrl/$workId/acceptances/$acceptanceId/status');
    final headers = await _getHeaders();
    final body = jsonEncode({'status': newStatus});

    try {
      final response = await http.put(url, headers: headers, body: body);

      print('📦 PUT $url');
      print('📤 Body: $body');
      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) return true;

      // Xử lý lỗi từ backend
      final decoded = jsonDecode(response.body);
      final error = decoded['error']?.toString().toUpperCase() ?? '';

      if (error.contains("COMPLETED")) {
        throw Exception("Công việc đã kết thúc, không thể thay đổi.");
      } else if (error.contains("CANCELLED")) {
        throw Exception("Bạn đã hủy công việc, không thể nhận lại.");
      } else if (error.contains("BẠN KHÔNG CÓ QUYỀN")) {
        throw Exception("Bạn không có quyền cập nhật trạng thái này.");
      } else {
        throw Exception("Chỉ chủ sở hữu mới được cập nhật.");
      }
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception("Phản hồi không hợp lệ từ máy chủ.");
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception("Không thể kết nối đến máy chủ. Kiểm tra mạng.");
    } catch (e) {
      print('❌ Exception: $e');
      throw Exception(e.toString());
    }
  }
}
