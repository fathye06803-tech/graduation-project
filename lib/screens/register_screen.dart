import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/screens/login_screen.dart';
import 'main_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

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
                      "Create Account",
                      style: TextStyle(
                        fontFamily: 'Montserrat-Regular',
                        fontSize: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Name
                  buildTextField("Full Name", controller: nameController),

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

                  /// Confirm Password
                  buildTextField(
                    "Confirm Password",
                    isPassword: true,
                    controller: confirmController,
                  ),

                  const SizedBox(height: 25),

                  /// Create Account Button
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

                        if (nameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            passwordController.text.isEmpty ||
                            confirmController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter all fields")),
                          );
                          return;
                        }

                        if (passwordController.text != confirmController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match")),
                          );
                          return;
                        }

                        try {

                          /// 🔥 create user
                          UserCredential userCredential =
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          /// 🔥 save user in firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .set({
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                          });

                          /// 🔥 go to home
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigation(),
                            ),
                          );

                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          color: AppColors.background,
                          fontFamily: 'Montserrat-SemiBold',
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// Login redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Login",
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