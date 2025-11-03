import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/account.dart';

class AdminService {
  // ✅ Endpoint gốc cho module Admin
  static String get _endpoint => "$baseUrl/admin";

  // 🧩 Helper: log phản hồi (dùng khi debug)
  void _logResponse(String action, http.Response response) {
    print('[AdminService][$action] ${response.statusCode} => ${response.body}');
  }

  // 📜 Lấy tất cả tài khoản
  Future<List<Account>> getAllAccounts(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
      _logResponse('GET all accounts', response);

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        return jsonList.map((e) => Account.fromJson(e)).toList();
      } else {
        throw Exception('❌ Không thể tải danh sách tài khoản: ${response.body}');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi kết nối server: $e');
    }
  }

  // 🔍 Lấy tài khoản theo ID
  Future<Account> getAccountById(int id, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _logResponse('GET account by ID', response);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return Account.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('❌ Không tìm thấy tài khoản: ${response.body}');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi tải thông tin tài khoản: $e');
    }
  }

  // 🔒 Khóa user
  Future<void> lockUser(int id, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_endpoint/lock/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _logResponse('LOCK user', response);

      if (response.statusCode != 200) {
        throw Exception('❌ Không thể khóa tài khoản');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi khóa tài khoản: $e');
    }
  }

  // 🔓 Mở khóa user
  Future<void> unlockUser(int id, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_endpoint/unlock/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _logResponse('UNLOCK user', response);

      if (response.statusCode != 200) {
        throw Exception('❌ Không thể mở khóa tài khoản');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi mở khóa tài khoản: $e');
    }
  }

  // 🗑️ Xóa user
  Future<void> deleteUser(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_endpoint/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _logResponse('DELETE user', response);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('❌ Xóa tài khoản thất bại: ${response.body}');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi xóa tài khoản: $e');
    }
  }

  // ✏️ Cập nhật thông tin user
  Future<void> updateUser(
      int id,
      String name,
      String email,
      String role,
      bool locked,
      String token, {
        String updatedBy = "admin",
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$_endpoint/update/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
          'locked': locked,
          'updatedBy': updatedBy,
        }),
      );
      _logResponse('UPDATE user', response);

      if (response.statusCode != 200) {
        throw Exception('❌ Cập nhật tài khoản thất bại');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi cập nhật tài khoản: $e');
    }
  }

  // 🔐 Đổi mật khẩu
  Future<void> changePassword(String oldPass, String newPass, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': oldPass,
          'newPassword': newPass,
        }),
      );
      _logResponse('CHANGE password', response);

      if (response.statusCode != 200) {
        throw Exception('❌ Đổi mật khẩu thất bại: ${response.body}');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi đổi mật khẩu: $e');
    }
  }

  // ➕ Tạo tài khoản mới
  Future<void> createUser({
    required String name,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required String role,
    required String token,
    Map<String, dynamic>? company,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
      };

      if (role == "ROLE_MANAGER" && company != null) {
        body['company'] = company;
      }

      final response = await http.post(
        Uri.parse('$_endpoint/create-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _logResponse('CREATE user', response);

      if (response.statusCode != 200) {
        throw Exception('❌ Tạo tài khoản thất bại: ${response.body}');
      }
    } catch (e) {
      throw Exception('🚫 Lỗi khi tạo tài khoản: $e');
    }
  }
}
