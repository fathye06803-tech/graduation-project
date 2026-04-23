import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blue_cash/core/theme/app_color.dart';

class EditGoalScreen extends StatefulWidget {
  final String goalId;
  final String title;
  final double target;
  final String timeFrame;

  const EditGoalScreen({
    super.key,
    required this.goalId,
    required this.title,
    required this.target,
    required this.timeFrame,
  });

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController titleController;
  late TextEditingController targetController;
  late String selectedTime;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    targetController = TextEditingController(text: widget.target.toString());
    selectedTime = widget.timeFrame;
  }

  Future<void> updateGoal() async {
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

      // نفس المنطق المستخدم في Add Goal لإعادة الحساب عند التعديل
      if (selectedTime == "29 day") {
        deadline = now.add(const Duration(days: 29));
        dailyInstallment = targetAmount / 29;
        monthlyInstallment = targetAmount;
      } else {
        int months = int.parse(selectedTime.split(' ')[0]);
        deadline = DateTime(now.year, now.month + months, now.day);
        monthlyInstallment = targetAmount / months;
        dailyInstallment = targetAmount / (months * 30);
      }

      await FirebaseFirestore.instance
          .collection('goals')
          .doc(widget.goalId)
          .update({
        'title': titleController.text.trim(),
        'target': targetAmount,
        'timeFrame': selectedTime,
        'deadline': Timestamp.fromDate(deadline), // تحديث التاريخ
        'monthlyInstallment': double.parse(monthlyInstallment.toStringAsFixed(2)), // تحديث القسط
        'dailyInstallment': double.parse(dailyInstallment.toStringAsFixed(2)),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Goal updated successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating goal: $e")),
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
          // Header Gradient
          Container(
            height: 220,
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
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Edit Your Goal",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: _inputStyle("What are you saving for?"),
                          ),
                          const SizedBox(height: 25),
                          _buildLabel("Target Amount (EGP)"),
                          TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: _inputStyle("e.g. 50000"),
                          ),
                          const SizedBox(height: 25),
                          _buildLabel("Time Frame"),
                          DropdownButtonFormField<String>(
                            value: selectedTime,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                            decoration: _inputStyle("Select Duration"),
                            items: [
                              "1 month",
                              "3 months",
                              "6 months",
                              "12 months",
                              "24 months",
                              "48 months"]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => selectedTime = val!),
                          ),

                          // Preview Card (Optional but helpful)
                          const SizedBox(height: 30),
                          _buildPreviewCard(),

                          const SizedBox(height: 40),
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
                              onPressed: isLoading ? null : updateGoal,
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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

  // ودجت إضافية لشكل جمالي بيوضح لليوزر إيه اللي هيتغير
  Widget _buildPreviewCard() {
    double? amt = double.tryParse(targetController.text);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Changing these values will recalculate your monthly savings plan.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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