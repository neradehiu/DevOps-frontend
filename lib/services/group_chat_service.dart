import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; // ✅ import baseUrl & wsPath

class GroupChatService {
  final _storage = const FlutterSecureStorage();
  StompClient? _stompClient;
  bool _isConnected = false;

  String? _token;
  String? _username;
  final _messages = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> get messages => _messages;

  // ✅ Dùng baseUrl tương đối — thích hợp khi Flutter Web & Backend chung domain
  String get wsUrl => "$wsPath";
  String get apiUrl => "$baseUrl/chat";

  /// 🔌 Kết nối WebSocket
  Future<void> connect({
    required Function(Map<String, dynamic>) onMessageReceived,
    Function()? onConnect,
    Function(dynamic error)? onError,
  }) async {
    _token = await _storage.read(key: 'token');
    _username = await _storage.read(key: 'username');

    if (_token == null || _username == null) {
      print('❌ Không thể kết nối WS: token hoặc username null');
      return;
    }

    print('🔐 Kết nối WS với token: $_token, username: $_username');

    _stompClient = StompClient(
      config: StompConfig.SockJS(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        onConnect: (StompFrame frame) {
          _isConnected = true;
          print('✅ WS Connected');

          _stompClient?.subscribe(
            destination: '/topic/chat/group',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                print('📥 WS Message nhận được: ${jsonEncode(data)}');
                updateMessage(data, onMessageReceived);
              }
            },
          );

          onConnect?.call();
        },
        beforeConnect: () async {
          print('⏳ Đang kết nối đến WS...');
          await Future.delayed(const Duration(milliseconds: 300));
        },
        onWebSocketError: onError ?? (error) => print('❌ WebSocket error: $error'),
        onDisconnect: (_) {
          _isConnected = false;
          print("❌ WS Disconnected");
        },
      ),
    );

    _stompClient?.activate();
  }

  /// 🔄 Cập nhật danh sách tin nhắn
  void updateMessage(Map<String, dynamic> data, Function(Map<String, dynamic>) callback) {
    final existingIndex = _messages.indexWhere((m) => m['id'] == data['id']);
    if (existingIndex != -1) {
      _messages[existingIndex] = data;
    } else {
      _messages.add(data);
    }
    callback(data);
  }

  /// 💬 Gửi tin nhắn nhóm
  void sendGroupMessage(String content) {
    if (!_isConnected || _stompClient == null) {
      print('⚠️ Không thể gửi: WebSocket chưa kết nối');
      return;
    }

    final message = {'content': content, 'type': 'GROUP'};
    print('📤 Gửi message: ${jsonEncode(message)}');

    _stompClient?.send(
      destination: '/app/chat.group',
      body: jsonEncode(message),
    );
  }

  /// 👁️ Đánh dấu đã đọc qua WebSocket
  void markAsReadWebSocket(int messageId) {
    if (!_isConnected || _stompClient == null) {
      print('⚠️ Không thể markRead: WS chưa kết nối');
      return;
    }

    print('📤 markAsReadWebSocket gửi ID: $messageId');
    _stompClient?.send(
      destination: '/app/chat.markRead',
      body: messageId.toString(),
      headers: {'Authorization': 'Bearer $_token'},
    );
  }

  /// ✅ Đánh dấu đã đọc qua REST API (fallback)
  Future<void> markAsReadRest(int messageId) async {
    final url = Uri.parse('$apiUrl/mark-read/$messageId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Tin nhắn $messageId đã đánh dấu (REST)");
    } else {
      print("❌ REST lỗi: ${response.body}");
    }
  }

  /// 👋 Ngắt kết nối WS
  void disconnect() {
    _stompClient?.deactivate();
    _isConnected = false;
    print('👋 WS Disconnected thủ công');
  }

  bool get isConnected => _isConnected;
}
