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

  // Function to search for user by email and add them to the goal members array
  Future<void> addUserToGoal(String email) async {
    if (email.isEmpty) return;

    try {
      // 1. Find user by email in 'users' collection
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found!")),
        );
        return;
      }

      // 2. Get the UID of the found user
      String newUserUid = userQuery.docs.first.id;

      // 3. Add the UID to the 'members' array in the specific goal document
      await FirebaseFirestore.instance
          .collection('goals')
          .doc(widget.goalId)
          .update({
        'members': FieldValue.arrayUnion([newUserUid])
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User added successfully!")),
      );
      _emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Dialog to input the partner's email
  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Partner"),
        content: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: "Enter partner's email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              addUserToGoal(_emailController.text);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        elevation: 0,
        title: const Text("Goal Details", style: TextStyle(color: Colors.white)),
        actions: [
          // Icon button to trigger the Add Partner dialog
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddMemberDialog,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Fetching from the global 'goals' collection
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.blue)),
                      const SizedBox(height: 20),
                      _buildInfoTile("Target Amount", "EGP ${target.toStringAsFixed(0)}", Icons.flag),
                      _buildInfoTile("Saved Amount", "EGP ${current.toStringAsFixed(0)}", Icons.account_balance_wallet,
                          color: isCompleted ? Colors.green : AppColors.blue),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress > 1 ? 1 : progress,
                          minHeight: 15,
                          backgroundColor: Colors.grey.shade300,
                          color: isCompleted ? Colors.green : AppColors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("${(progress * 100).toStringAsFixed(1)}% Completed", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 40),
                      const Text("Contributions Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Sub-collection 'deposits' inside the goal document
                      _buildDepositsList(widget.goalId),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildAddButton(context, isCompleted),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AppColors.blue),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      subtitle: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildDepositsList(String goalId) {
    return StreamBuilder<QuerySnapshot>(
      // Order deposits by creation time
      stream: FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .collection('deposits')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var d = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                // Use the saved color for the avatar
                leading: CircleAvatar(backgroundColor: Color(d['color'] ?? AppColors.blue.value)),
                title: Text(d['userName'] ?? "User"),
                trailing: Text("+EGP ${d['amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.grey : AppColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          onPressed: isCompleted ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddDepositScreen(goalName: widget.title, goalId: widget.goalId))),
          child: Text(isCompleted ? "Goal Achieved!" : "Add My Contribution", style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}