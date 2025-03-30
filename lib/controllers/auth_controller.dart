import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../controllers/document_controller.dart';

class AuthController extends GetxController {
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final _isLoading = false.obs;

  UserModel? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  bool get isLoggedIn => _currentUser.value != null;

  // Get Supabase client
  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();

    // Check for existing session
    final session = supabase.auth.currentSession;
    if (session != null) {
      fetchCurrentUser();
    }

    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await fetchCurrentUser();

        // Also fetch documents on sign in
        final documentController = Get.find<DocumentController>();
        await documentController.fetchDocuments();

        // Navigate to home if needed
        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser.value = null;
      }
    });
  }

  Future<void> fetchCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await supabase.from('profiles').select().eq('id', user.id).single();

        _currentUser.value = UserModel.fromJson({
          ...userData,
          'id': user.id,
          'email': user.email ?? '',
        });
      } catch (e) {
        print('Error fetching user data: $e');
        // Create user profile if it doesn't exist
        if (user.email != null) {
          _currentUser.value = UserModel(
            id: user.id,
            email: user.email!,
            name: user.userMetadata?['full_name'],
          );

          // Create profile in database
          await supabase.from('profiles').upsert({
            'id': user.id,
            'email': user.email,
            'name': user.userMetadata?['full_name'],
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading.value = true;
      await supabase.auth.signInWithPassword(email: email, password: password);

      // Make sure user data is loaded
      await fetchCurrentUser();

      // Fetch documents after login
      final documentController = Get.find<DocumentController>();
      await documentController.fetchDocuments();

      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      _isLoading.value = true;
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      Get.snackbar(
        'Success',
        'Account created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error signing up: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      await supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );

      // We can't directly fetch documents here because OAuth is asynchronous
      // The onAuthStateChange listener will handle fetching the user data
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await supabase.auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }
}
