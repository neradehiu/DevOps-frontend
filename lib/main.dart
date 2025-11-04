import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'controllers/theme_controller.dart';
import 'screens/admin_create_account_screen.dart';
import 'screens/admin_notifications_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/private_chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ThemeController());
  final storage = FlutterSecureStorage();

  // Đọc username và khởi tạo chat service
  final String? username = await storage.read(key: 'username');
  final PrivateChatService chatService = PrivateChatService();

  if (username != null) {
    await chatService.connect(onMessageReceived: (msg) {
      print('📩 Tin nhắn nhận: $msg');
    });
  }

  runApp(MyApp(
    chatService: chatService,
  ));
}

class MyApp extends StatelessWidget {
  final PrivateChatService chatService;

  const MyApp({
    super.key,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() => GetMaterialApp(
      title: 'Find Work For Everyone',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F1FB),
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/user', page: () => const UserScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/admin/create', page: () => const AdminCreateAccountScreen()),

        GetPage(
          name: '/admin/reports',
          page: () => AdminNotificationsScreen(
            chatService: chatService, // Không cần truyền currentUsername nữa
          ),
        ),

        GetPage(name: '/admin/profile', page: () => const AdminProfileScreen()),
        GetPage(name: '/admin/settings', page: () => const AdminSettingsScreen()),
      ],
    ));
  }
}
