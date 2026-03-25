import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/screens/login_screen.dart';

import 'login_screen.dart';
import 'main_navigation.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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

                  buildTextField("Full Name"),
                  const SizedBox(height: 25),

                  buildTextField("Email"),
                  const SizedBox(height: 25),

                  buildTextField("Password", isPassword: true),
                  const SizedBox(height: 25),

                  buildTextField("Confirm Password", isPassword: true),

                  const SizedBox(height: 25),

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
                      onPressed: () {},
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                            color: AppColors.background,
                            fontFamily: 'Montserrat-SemiBold',
                            fontSize: 17),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

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

  Widget buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
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