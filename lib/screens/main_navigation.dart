import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'my_goals_screen.dart';
import 'ai_screen.dart';
import 'saving_history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 0;

  final List<Widget> screens = const [
    MyGoalsScreen(),
    AiScreen(),
    SavingsHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem("assets/icon/my_goals.svg", 0),
            navItem("assets/icon/ai logo.svg", 1),
            navItem("assets/icon/saving_history.svg", 2),
            navItem("assets/icon/profile.svg", 3),
          ],
        ),
      ),
    );
  }

  /// ✅ Nav Item
  Widget navItem(String iconPath, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isSelected ? 12 : 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withOpacity(0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,

            /// 🔥 أهم سطر (بيحل مشكلة اللون + الظهور)
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.blue : Colors.grey.shade500,
              BlendMode.srcIn,
            ),

            placeholderBuilder: (context) => Icon(
              size: 24,
              Icons.error,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}