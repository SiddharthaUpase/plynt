import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'controllers/auth_controller.dart';
import 'controllers/document_controller.dart';
import 'controllers/chat_controller.dart';
import 'views/login_view.dart';
import 'views/signup_view.dart';
import 'views/home_view.dart';
import 'views/splash_view.dart';

// Environment variables from dart-define
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);
const String openaiApiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use Flutter's built-in kReleaseMode to detect development mode
  final bool isDevelopment = !kReleaseMode;

  String apiUrl = supabaseUrl;
  String apiKey = supabaseAnonKey;
  String apiOpenAIKey = openaiApiKey;

  // Only load environment variables from .env files in development mode
  if (isDevelopment) {
    print(
      "Running in development mode - loading environment variables from .env files",
    );
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print("Failed to load .env file: $e");
      // Try to load the fallback file if the main .env fails
      try {
        await dotenv.load(fileName: ".env.default");
      } catch (e) {
        print("Failed to load .env.default file: $e");
      }
    }

    // In development mode, use .env values if available
    apiUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    apiKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
    apiOpenAIKey = dotenv.env['OPENAI_API_KEY'] ?? openaiApiKey;

    // Debug prints for development mode
    print('Development mode - API URL: $apiUrl');
    print('Development mode - API KEY: $apiKey');
    print('Development mode - OPENAI API KEY: $apiOpenAIKey');
  } else {
    print(
      "Running in production mode - using dart-define environment variables",
    );
  }

  // Initialize Supabase
  await Supabase.initialize(url: apiUrl, anonKey: apiKey);

  // Register controllers
  Get.put(AuthController(), permanent: true);
  Get.put(DocumentController(), permanent: true);
  // Pass the OpenAI API key to your chat controller
  Get.put(ChatController(apiKey: apiOpenAIKey), permanent: true);

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
