import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/core/services/notification_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  String selectedTime = "1 month";
  final TextEditingController titleController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  bool isLoading = false;

  Future<void> addGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.isEmpty || targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      double targetAmount = double.parse(targetController.text.trim());
      DateTime now = DateTime.now();
      DateTime deadline;
      double monthlyInstallment = 0;
      double dailyInstallment = 0;

      if (selectedTime == "1 month") {
        deadline = now.add(const Duration(days: 30));
        dailyInstallment = targetAmount / 30;
        monthlyInstallment = targetAmount;
      } else {
        int months = int.parse(selectedTime.split(' ')[0]);
        deadline = DateTime(now.year, now.month + months, now.day);
        monthlyInstallment = targetAmount / months;
        dailyInstallment = targetAmount / (months * 30);
      }

      String safeName = user.displayName ?? user.email?.split('@')[0] ?? "User";

      await FirebaseFirestore.instance.collection('goals').add({
        'title': titleController.text.trim(),
        'target': targetAmount,
        'current': 0.0,
        'timeFrame': selectedTime,
        'deadline': Timestamp.fromDate(deadline),
        'monthlyInstallment': double.parse(monthlyInstallment.toStringAsFixed(2)),
        'dailyInstallment': double.parse(dailyInstallment.toStringAsFixed(2)),
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': user.uid,
        'creatorName': safeName,
        'members': [user.uid],
        'isAutoDeduct': true,
      });


      await NotificationService.scheduleGoalReminder(
        goalName: titleController.text.trim(),
        targetDate: deadline,
        totalAmount: targetAmount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Goal created with smart notifications!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "New Goal",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Goal Name"),
                          TextField(
                            controller: titleController,
                            decoration: _inputStyle("New Car"),
                          ),
                          const SizedBox(height: 25),
                          _buildLabel("Target Amount"),
                          TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("50000"),
                          ),
                          const SizedBox(height: 25),
                          _buildLabel("Time Frame"),
                          DropdownButtonFormField<String>(
                            value: selectedTime,
                            dropdownColor: Colors.white,
                            decoration: _inputStyle(""),
                            items: [
                              "1 month",
                              "3 months",
                              "6 months",
                              "12 months",
                              "24 months",
                              "48 months"
                            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => selectedTime = val!),
                          ),
                          const SizedBox(height: 50),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading ? null : addGoal,
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                "Create Goal",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    );
  }
}