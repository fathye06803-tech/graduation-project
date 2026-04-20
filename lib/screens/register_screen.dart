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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Image.asset(
                "assets/image/logo.png",
                width: 180,
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    buildTextField("Full Name", controller: nameController),
                    const SizedBox(height: 20),
                    buildTextField("Email", controller: emailController),
                    const SizedBox(height: 20),
                    buildTextField(
                      "Password",
                      isPassword: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 20),
                    buildTextField(
                      "Confirm Password",
                      isPassword: true,
                      controller: confirmController,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
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
                            UserCredential userCredential =
                            await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                            );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCredential.user!.uid)
                                .set({
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                            });

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
                    const SizedBox(height: 40),
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
      ),
    );
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}