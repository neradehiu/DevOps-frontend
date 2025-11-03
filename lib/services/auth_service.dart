import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../config/api_config.dart';

class AuthService {
  static const storage = FlutterSecureStorage();

  // ✅ Dùng baseUrl thống nhất từ api_config.dart
  static const String basePath = "$baseUrl/auth";

  // ---------------------- 🧾 REGISTER ----------------------
  Future<String?> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$basePath/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('📩 [REGISTER] ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) return null;

      return _extractErrorMessage(response);
    } catch (e) {
      print('❌ [REGISTER ERROR] $e');
      return 'Đã xảy ra lỗi khi đăng ký: $e';
    }
  }

  // ---------------------- 🔑 LOGIN ----------------------
  Future<String?> login(
      LoginRequest request,
      Function(String role) onSuccess,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$basePath/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('📩 [LOGIN] ${response.statusCode} - ${response.body}');

      // ✅ Kiểm tra nếu server không trả JSON (ví dụ HTML)
      if (response.headers['content-type']?.contains('application/json') == false) {
        print('⚠️ Server trả về không phải JSON: ${response.body}');
        return 'Phản hồi không hợp lệ từ máy chủ.';
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token']?.toString();
        final role = json['role']?.toString();
        final username = json['username']?.toString();
        final id = json['id']?.toString();

        if (token == null || role == null) {
          return 'Phản hồi không hợp lệ: thiếu token hoặc role';
        }

        // ✅ Lưu vào FlutterSecureStorage
        await storage.write(key: 'token', value: token);
        await storage.write(key: 'role', value: role);
        if (username != null) await storage.write(key: 'username', value: username);
        if (id != null) await storage.write(key: 'id', value: id);

        print('✅ Đăng nhập thành công - Role: $role, User: $username');
        onSuccess(role);
        return null;
      }

      return _extractErrorMessage(response);
    } catch (e) {
      print('❌ [LOGIN ERROR] $e');
      return 'Lỗi đăng nhập: $e';
    }
  }

  // ---------------------- 🔁 FORGOT PASSWORD ----------------------
  Future<String?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$basePath/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📩 [FORGOT PASSWORD] ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) return null;
      return _extractErrorMessage(response);
    } catch (e) {
      print('❌ [FORGOT PASSWORD ERROR] $e');
      return 'Không thể gửi email khôi phục: $e';
    }
  }

  // ---------------------- ✅ VERIFY CODE ----------------------
  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$basePath/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      print('📩 [VERIFY CODE] ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ [VERIFY CODE ERROR] $e');
      return false;
    }
  }

  // ---------------------- 🔐 RESET PASSWORD ----------------------
  Future<String?> resetPassword(
      String email,
      String code,
      String newPassword,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$basePath/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      print('📩 [RESET PASSWORD] ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) return null;
      return _extractErrorMessage(response);
    } catch (e) {
      print('❌ [RESET PASSWORD ERROR] $e');
      return 'Lỗi đặt lại mật khẩu: $e';
    }
  }

  // ---------------------- 🚪 LOGOUT ----------------------
  Future<bool> logout() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$basePath/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📩 [LOGOUT] ${response.statusCode} - ${response.body}');
      await storage.deleteAll(); // Luôn xóa token local
      return response.statusCode == 200;
    } catch (e) {
      print('❌ [LOGOUT ERROR] $e');
      await storage.deleteAll();
      return false;
    }
  }

  // ---------------------- 💾 LOCAL STORAGE ----------------------
  Future<int?> getAccountId() async {
    final id = await storage.read(key: 'id');
    return id != null ? int.tryParse(id) : null;
  }

  Future<String?> getToken() => storage.read(key: 'token');
  Future<String?> getRole() => storage.read(key: 'role');
  Future<String?> getUsername() => storage.read(key: 'username');
  Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ---------------------- ⚙️ PRIVATE HELPERS ----------------------
  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      return json['message'] ?? 'Lỗi không xác định (${response.statusCode})';
    } catch (_) {
      return 'Lỗi: ${response.body}';
    }
  }
}
