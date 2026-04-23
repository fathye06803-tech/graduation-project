import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_deposit.dart';

class GoalDetailsScreen extends StatefulWidget {
  final String goalId;
  final String title;

  const GoalDetailsScreen({super.key, required this.goalId, required this.title});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> addUserToGoal(String email) async {
    if (email.isEmpty) return;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found!")));
        return;
      }

      String newUserUid = userQuery.docs.first.id;
      await FirebaseFirestore.instance.collection('goals').doc(widget.goalId).update({
        'members': FieldValue.arrayUnion([newUserUid])
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User added successfully!")));
      _emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Partner"),
        content: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Enter partner's email",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              addUserToGoal(_emailController.text);
              Navigator.pop(context);
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // AppBar Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Goal Details",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                    onPressed: _showAddMemberDialog,
                  ),
                ],
              ),
            ),
          ),

          // Main Content Container
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('goals').doc(widget.goalId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Goal not found"));

                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  double target = (data['target'] ?? 0).toDouble();
                  double current = (data['current'] ?? 0).toDouble();
                  double progress = target > 0 ? (current / target) : 0;
                  bool isCompleted = current >= target;

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.blue)),
                              const SizedBox(height: 20),

                              // Monthly Savings Target Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: Column(
                                  children: [
                                    const Text("Monthly Savings Target", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    Text(
                                      "EGP ${data['monthlyInstallment']?.toStringAsFixed(0) ?? '0'}",
                                      style: const TextStyle(fontSize: 32, color: AppColors.blue, fontWeight: FontWeight.bold),
                                    ),
                                    if (data['deadline'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          "Deadline: ${(data['deadline'] as Timestamp).toDate().year}",
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),
                              _buildInfoRow("Target", "EGP ${target.toStringAsFixed(0)}", Icons.outlined_flag),
                              const SizedBox(height: 12),
                              _buildInfoRow("Saved", "EGP ${current.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined, color: isCompleted ? Colors.green : AppColors.blue),

                              const SizedBox(height: 25),
                              // Progress Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("${(progress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress > 1 ? 1 : progress,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  color: isCompleted ? Colors.green : AppColors.blue,
                                ),
                              ),

                              const SizedBox(height: 35),
                              const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              _buildDepositsList(widget.goalId),
                              const SizedBox(height: 80), // Space for button
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Fixed Bottom Button
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('goals').doc(widget.goalId).snapshots(),
          builder: (context, snapshot) {
            bool isCompleted = false;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              isCompleted = (data['current'] ?? 0) >= (data['target'] ?? 0);
            }
            return _buildAddButton(context, isCompleted);
          }
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.blue, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDepositsList(String goalId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('goals').doc(goalId).collection('deposits').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No contributions yet", style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            var d = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade100)
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(d['color'] ?? AppColors.blue.value).withOpacity(0.2),
                    child: Icon(Icons.person, color: Color(d['color'] ?? AppColors.blue.value), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(d['date'] != null ? (d['date'] as Timestamp).toDate().toString().split(' ')[0] : "", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const Spacer(),
                  Text("+ EGP ${d['amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.green.shade400 : AppColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0),
          onPressed: isCompleted ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddDepositScreen(goalName: widget.title, goalId: widget.goalId))),
          child: Text(isCompleted ? "Goal Achieved! 🎉" : "Add My Contribution", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}