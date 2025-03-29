import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'controllers/auth_controller.dart';
import 'controllers/document_controller.dart';
import 'controllers/chat_controller.dart';
import 'views/login_view.dart';
import 'views/signup_view.dart';
import 'views/home_view.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  // Replace with your Supabase URL and anon key
  await Supabase.initialize(
    url: 'https://ymkaebbyuiqfbjvifsjt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlta2FlYmJ5dWlxZmJqdmlmc2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwNDEyNzksImV4cCI6MjA1ODYxNzI3OX0.H7aMBXv7MoftclnV23Nlf5VPrqLYEL6wlXLSvu7_734',
  );

  // Register controllers
  Get.put(AuthController(), permanent: true);
  Get.put(DocumentController(), permanent: true);
  Get.put(ChatController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Supabase Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
        Get.put(DocumentController(), permanent: true);
      }),
      getPages: [
        GetPage(name: '/', page: () => const SplashView()),
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/signup', page: () => SignupView()),
        GetPage(name: '/home', page: () => HomeView()),
      ],
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}
