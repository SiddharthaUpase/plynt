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
import 'package:google_fonts/google_fonts.dart';

// Environment variables from dart-define
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String apiUrl = supabaseUrl;
  String apiKey = supabaseAnonKey;

  //if the domain is localhost, use the keys from the .env file
  if (Uri.base.host.contains('localhost')) {
    await dotenv.load(fileName: '.env');
    print('Running on localhost, getting supabase keys from .env file');
    apiUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    apiKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
  } else {
    print(
      'Running on production, using supabase keys from environment variables',
    );
  }

  // Initialize Supabase
  await Supabase.initialize(url: apiUrl, anonKey: apiKey);

  // Register controllers
  Get.put(AuthController(), permanent: true);
  Get.put(DocumentController(), permanent: true);
  // Pass the OpenAI API key to your chat controller
  Get.put(ChatController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'plynt',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202123),
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple.shade300,
          surface: const Color(0xFF343541),
          background: const Color(0xFF202123),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF343541),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF343541),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF343541),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.deepPurple.shade300),
          ),
          labelStyle: TextStyle(color: Colors.grey[400]),
        ),
        textTheme: GoogleFonts.aBeeZeeTextTheme(ThemeData.dark().textTheme),
        fontFamily: GoogleFonts.aBeeZee().fontFamily,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.deepPurple,
          selectionColor: Color.fromARGB(94, 147, 112, 216),
          selectionHandleColor: Colors.deepPurple,
        ),
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
