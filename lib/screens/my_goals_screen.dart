import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'add_goal_screen.dart';
import 'goal_detalis.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Blue Header
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

          /// Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      "assets/icon/back.svg",
                      color: AppColors.background,
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "My Goals",
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

          /// Goals Container
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

              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [

                  GoalCard(
                    title: "New Car",
                    current: 7500,
                    target: 10000,
                  ),

                  SizedBox(height: 20),

                  GoalCard(
                    title: "Saving",
                    current: 10000,
                    target: 20000,
                  ),

                  SizedBox(height: 20),

                  GoalCard(
                    title: "Rent",
                    current: 750,
                    target: 1000,
                  ),

                  SizedBox(height: 20),

                  GoalCard(
                    title: "Education",
                    current: 3500,
                    target: 10000,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// زرار Add
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        child: SvgPicture.asset(
          "assets/icon/add.svg",
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddGoalScreen(),
            ),
          );
        },
      ),
    );
  }
}

class GoalCard extends StatelessWidget {

  final String title;
  final double current;
  final double target;
  final String timeFrame;

  const GoalCard({
    super.key,
    required this.title,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {

    double progress = current / target;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailsScreen(
              goalName: title,
              targetAmount: target,
              savedAmount: current,
              timeFrame: "12 months",
            ),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Goal Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
              ),
            ),

            const SizedBox(height: 6),

            /// Amount
            Text(
              "\$ ${current.toStringAsFixed(0)} / \$ ${target.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 18,
                backgroundColor: Colors.grey.shade300,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}