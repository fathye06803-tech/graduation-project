import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/screens/register_screen.dart';
import 'main_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 80),

            Image.asset(
              "assets/image/logo.png",
              width: 200,
            ),

            const SizedBox(height: 20),

            const Text(
              "Welcome",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.background,
                fontSize: 34,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "A few can do the impossible",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.background,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 80),

            Container(
              padding: const EdgeInsets.all(230),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontFamily: 'Montserrat-Regular',
                        fontSize: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Email
                  buildTextField("Email", controller: emailController),

                  const SizedBox(height: 25),

                  /// Password
                  buildTextField(
                    "Password",
                    isPassword: true,
                    controller: passwordController,
                  ),

                  const SizedBox(height: 25),

                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {

                        if (emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter all fields")),
                          );
                          return;
                        }

                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigation(),
                            ),
                          );

                        } on FirebaseAuthException catch (e) {
                          print("Firebase Auth Error: ${e.code}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message ?? "Login Failed")),
                          );
                        } catch (e) {
                          // للأخطاء العامة
                          print("General Error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("An error occurred")),
                          );
                        }
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: AppColors.background,
                          fontFamily: 'Montserrat-SemiBold',
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: AppColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🔥 TextField مع Controller
  Widget buildTextField(
      String hint, {
        bool isPassword = false,
        required TextEditingController controller,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}