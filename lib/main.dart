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

  // Try to load environment variables from .env files
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    try {
      await dotenv.load(fileName: ".env.default");
      print('Using default environment configuration');
    } catch (e) {
      print('Could not load .env files, using dart-define values');
    }
  }

  // Get API keys from dotenv or use dart-define defaults
  final String apiUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
  final String apiKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;

  // Store the OpenAI API key in a global variable or pass it to your controller
  final String apiOpenAIKey = dotenv.env['OPENAI_API_KEY'] ?? openaiApiKey;

  //print the api keys
  print('API URL: $apiUrl');
  print('API KEY: $apiKey');
  print('OPENAI API KEY: $apiOpenAIKey');

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
