import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<String> labels = ["Goals", "AI Assistant", "History", "Profile"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(bottom: 20), // مسافة من تحت الموبايل
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(screens.length, (index) {
            return _buildNavItem(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = currentIndex == index;
    final List<String> icons = [
      "assets/icon/my_goals.svg",
      "assets/icon/ai logo.svg",
      "assets/icon/saving_history.svg",
      "assets/icon/profile.svg",
    ];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  icons[index],
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isSelected ? AppColors.blue : Colors.grey.shade400,
                    BlendMode.srcIn,
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 10,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}