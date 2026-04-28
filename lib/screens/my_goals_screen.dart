import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_goal_screen.dart';
import 'goal_detalis.dart';
import 'edit_goal_screen.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header Gradient
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Text(
                    "My Goals",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 140),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .where('members', arrayContains: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                  }

                  final goals = snapshot.data!.docs;

                  if (goals.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final doc = goals[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return GoalCard(
                        goalId: doc.id,
                        title: data["title"] ?? "",
                        current: (data["current"] ?? 0).toDouble(),
                        target: (data["target"] ?? 0).toDouble(),
                        timeFrame: data["timeFrame"] ?? "",
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No goals yet",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

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
    double progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
    bool isCompleted = current >= target;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalDetailsScreen(goalId: goalId, title: title),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                _buildActionButtons(context),
              ],
            ),
            const SizedBox(height: 12),
            // Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "EGP ${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Professional Multi-User Progress Bar
            _buildMultiUserProgressBar(progress),

            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: const [
                    Icon(Icons.stars_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "Goal Completed! 🎉",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiUserProgressBar(double totalProgress) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .collection('deposits')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Default bar if no deposits yet
          return _baseProgressBar(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalProgress,
              child: Container(color: AppColors.blue),
            ),
          );
        }

        // Calculation for individual contributions
        Map<String, double> contributions = {};
        for (var doc in snapshot.data!.docs) {
          String userId = doc['userId'] ?? 'unknown';
          double amount = (doc['amount'] ?? 0).toDouble();
          contributions[userId] = (contributions[userId] ?? 0) + amount;
        }

        // Different colors for different users
        List<Color> palette = [AppColors.blue, Colors.orangeAccent, Colors.teal, Colors.purpleAccent, Colors.amber];

        return _baseProgressBar(
          child: Row(
            children: contributions.entries.map((entry) {
              int idx = contributions.keys.toList().indexOf(entry.key);
              double ratio = entry.value / target;
              if (ratio <= 0) return const SizedBox.shrink();

              return Expanded(
                flex: (ratio * 1000).toInt(),
                child: Container(color: palette[idx % palette.length]),
              );
            }).toList()..add(
              // Empty space
                Expanded(
                  flex: ((1 - totalProgress).clamp(0, 1) * 1000).toInt(),
                  child: Container(color: Colors.transparent),
                )
            ),
          ),
        );
      },
    );
  }

  Widget _baseProgressBar({required Widget child}) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_note_rounded, color: AppColors.blue, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditGoalScreen(
                goalId: goalId,
                title: title,
                target: target,
                timeFrame: timeFrame,
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Goal?"),
        content: const Text("This will permanently remove the goal and all transaction history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final goalRef = FirebaseFirestore.instance.collection('goals').doc(goalId);
      final deposits = await goalRef.collection('deposits').get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in deposits.docs) { batch.delete(doc.reference); }
      batch.delete(goalRef);
      await batch.commit();
    }
  }
}