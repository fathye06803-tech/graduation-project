import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_goal_screen.dart';
import 'goal_detalis.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Background
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

          /// Header
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
                        AppColors.background,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
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

          /// Content
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

              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading goals"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final goals = snapshot.data!.docs;

                  if (goals.isEmpty) {
                    return const Center(child: Text("No goals yet"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {

                      final doc = goals[index]; // مهم
                      final data = doc.data() as Map<String, dynamic>;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: GoalCard(
                          goalId: doc.id, // أهم سطر
                          title: data["title"] ?? "",
                          current: (data["current"] ?? 0).toDouble(),
                          target: (data["target"] ?? 0).toDouble(),
                          timeFrame: data["timeFrame"] ?? "",
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      /// ➕ Add Button
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


///  Goal Card
class GoalCard extends StatelessWidget {

  final String goalId;
  final String title;
  final double current;
  final double target;
  final String timeFrame;

  const GoalCard({
    super.key,
    required this.goalId,
    required this.title,
    required this.current,
    required this.target,
    required this.timeFrame,
  });

  @override
  Widget build(BuildContext context) {

    double progress = target > 0 ? current / target : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailsScreen(
              goalId: goalId,
              title: title,
              target: target,
              current: current,
              timeFrame: timeFrame,
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

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "\$ ${current.toStringAsFixed(0)} / \$ ${target.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

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