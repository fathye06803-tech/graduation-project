import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_deposit.dart';

class GoalDetailsScreen extends StatelessWidget {
  final String goalId;
  final String title;

  const GoalDetailsScreen({
    super.key,
    required this.goalId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(goalId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Goal not found"));
          }

          var goalData = snapshot.data!.data() as Map<String, dynamic>;
          double target = (goalData['target'] ?? 0).toDouble();

          // Logic to make sure current doesn't exceed target
          double rawCurrent = (goalData['current'] ?? 0).toDouble();
          double current = rawCurrent > target ? target : rawCurrent;

          String timeFrame = goalData['timeframe'] ?? "Not set";
          double progress = target > 0 ? current / target : 0;

          // Check if goal is completed
          bool isCompleted = progress >= 1.0;

          return Stack(
            children: [
              Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blue, AppColors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        "Goal Details",
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text("Target Amount", style: TextStyle(fontSize: 16)),
                        Text(
                          "EGP ${target.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        const Text("Saved Amount", style: TextStyle(fontSize: 16)),
                        Text(
                          "EGP ${current.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green : AppColors.blue,
                          ),
                        ),
                        const SizedBox(height: 25),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade300,
                            color: isCompleted ? Colors.green : AppColors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isCompleted
                              ? "Goal Achieved! 🎉"
                              : "${(progress * 100).toStringAsFixed(1)}% completed",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? Colors.green : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text("Time Frame", style: TextStyle(fontSize: 16)),
                        Text(
                          timeFrame,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted ? Colors.grey : AppColors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            // Disable button if goal is completed
                            onPressed: isCompleted ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddDepositScreen(
                                    goalName: title,
                                    goalId: goalId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              isCompleted ? "Goal Completed" : "Add Deposit",
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}