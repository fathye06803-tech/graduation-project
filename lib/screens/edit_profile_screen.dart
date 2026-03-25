import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditProfileScreen extends StatefulWidget {

  final String name;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  late TextEditingController nameController;
  late TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Header
          Container(
            height: 260,
            width: double.infinity,
            color: AppColors.blue,
          ),

          /// Title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:16),
              child: Row(
                children: [

                  IconButton(
                    icon: SvgPicture.asset(
                      "assets/icon/back.svg",
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width:20),

                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
            ),
          ),

          /// Body
          Padding(
            padding: const EdgeInsets.only(top:160),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    const SizedBox(height:30),

                    /// Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height:20),

                    /// Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height:20),

                    /// Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// Save Button
                    SizedBox(
                      width: double.infinity,
                      height:55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
                        onPressed: () {

                          String newName = nameController.text;
                          String newEmail = emailController.text;
                          String newPassword = passwordController.text;

                          /// هنا هتربط الداتا بيز بعدين

                        },
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:18),
                        ),
                      ),
                    ),

                    const SizedBox(height:20),

                  ],
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
}