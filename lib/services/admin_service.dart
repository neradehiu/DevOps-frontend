import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account.dart';

class AdminService {
  // 🔧 BASE_URL linh hoạt: local, Docker, VPS
  static const String baseHost = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://165.22.55.126:8080',
  );

  static const String baseUrl = '$baseHost/api/admin';

  // 🧩 Helper để log gọn gàng
  void _logResponse(String action, http.Response response) {
    print('[$action] -> ${response.statusCode} | ${response.body}');
  }

  Future<List<Account>> getAllAccounts(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    _logResponse('GET all accounts', response);

    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Account.fromJson(e)).toList();
    } else {
      throw Exception('❌ Failed to load accounts: ${response.body}');
    }
  }

  Future<Account> getAccountById(int id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    _logResponse('GET account by ID', response);

    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != 'null') {
      return Account.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('❌ Failed to load account: ${response.body}');
    }
  }

  Future<void> lockUser(int id, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/lock/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _logResponse('LOCK user', response);
    if (response.statusCode != 200) {
      throw Exception('❌ Failed to lock user');
    }
  }

  Future<void> unlockUser(int id, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/unlock/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _logResponse('UNLOCK user', response);
    if (response.statusCode != 200) {
      throw Exception('❌ Failed to unlock user');
    }
  }

  Future<void> deleteUser(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _logResponse('DELETE user', response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('❌ Failed to delete user');
    }
  }

  Future<void> updateUser(
      int id,
      String name,
      String email,
      String role,
      bool locked,
      String token, {
        String updatedBy = "admin",
      }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update/$id'),
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
      throw Exception('❌ Failed to update user');
    }
  }

  Future<void> changePassword(String oldPass, String newPass, String token) async {
    // ✅ Sửa đường dẫn đúng: chỉ /change-password, không lặp /api/admin
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
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
      throw Exception('❌ Đổi mật khẩu thất bại');
    }
  }

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
      Uri.parse('$baseUrl/create-account'),
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
  }
}
