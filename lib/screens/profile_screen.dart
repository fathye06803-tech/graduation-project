import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/screens/edit_profile_screen.dart';
import 'package:blue_cash/screens/login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Header
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue,
                  AppColors.blue,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// Back + Title
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  const SizedBox(width: 20),

                  const Text(
                    "Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Body
          Padding(
            padding: const EdgeInsets.only(top: 160),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),

              child: Column(
                children: [

                  const SizedBox(height: 40),

                  /// Profile Image
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("assets/images/user.png"),
                  ),

                  const SizedBox(height: 15),

                  /// User Name
                  const Text(
                    "Fathy",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// Email
                  const Text(
                    "fathy@email.com",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [

                        /// Total Savings
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [

                                Text(
                                  "\$ 3,500",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                  ),
                                ),

                                SizedBox(height: 5),

                                Text(
                                  "Total Savings",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        /// Goals Count
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [

                                Text(
                                  "3",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                  ),
                                ),

                                SizedBox(height: 5),

                                Text(
                                  "Goals",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Edit Profile
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/icon/edit.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.blue,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: const Text("Edit Profile"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () { Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          name: "Fathy",
                          email: "fathy@email.com",
                        ),
                      ),
                    );},
                  ),

                  /// Logout
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/icon/logout.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: const Text("Logout"),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                      (route) => false,
                                );
                              },
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}