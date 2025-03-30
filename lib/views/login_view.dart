import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202123), // Dark background like ChatGPT
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start, // Align to start instead of stretch
                  children: [
                    // Brand logo at the top
                    Center(
                      child: Text(
                        'plynt',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      //ta
                    ),
                    //tagline
                    Center(
                      child: Text(
                        'Your Documents, Our Intelligence',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.grey[400]),
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
                          borderSide: BorderSide(
                            color: Colors.deepPurple.shade300,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF343541),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey[400]),
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
                          borderSide: BorderSide(
                            color: Colors.deepPurple.shade300,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF343541),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              authController.isLoading
                                  ? null
                                  : () => authController.signInWithEmail(
                                    emailController.text,
                                    passwordController.text,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.deepPurple
                                .withOpacity(0.5),
                          ),
                          child:
                              authController.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed('/signup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[300],
                          side: BorderSide(color: Colors.grey.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    // const SizedBox(height: 32),
                    // const Divider(
                    //   color: Color(0xFF444654),
                    //   thickness: 1,
                    //   height: 32,
                    // ),
                    // const Align(
                    //   alignment: Alignment.center,
                    //   child: Text(
                    //     'Or sign in with',
                    //     textAlign: TextAlign.center,
                    //     style: TextStyle(color: Colors.grey),
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // Obx(
                    //   () => SizedBox(
                    //     width: double.infinity,
                    //     child: ElevatedButton.icon(
                    //       icon: const Icon(Icons.g_mobiledata, size: 24),
                    //       label: const Text(
                    //         'Sign in with Google',
                    //         style: TextStyle(color: Colors.white, fontSize: 16),
                    //       ),
                    //       onPressed:
                    //           authController.isLoading
                    //               ? null
                    //               : authController.signInWithGoogle,
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: const Color(0xFF343541),
                    //         foregroundColor: Colors.white,
                    //         padding: const EdgeInsets.symmetric(vertical: 16),
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(8),
                    //           side: BorderSide(color: Colors.grey.shade700),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // // Debug button to fill test data
                    // Center(
                    //   child: Opacity(
                    //     opacity: 0.5,
                    //     child: TextButton(
                    //       onPressed: () {
                    //         emailController.text = 's1dupase34@gmail.com';
                    //         passwordController.text = 'Sid@1234';
                    //       },
                    //       child: const Text(
                    //         'Debug Fill',
                    //         style: TextStyle(fontSize: 12, color: Colors.grey),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
