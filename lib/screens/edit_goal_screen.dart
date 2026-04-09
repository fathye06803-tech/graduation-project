import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// 🔥 Update Goal Function
  Future<void> updateGoal() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must login first")),
      );
      return;
    }

    if (titleController.text.isEmpty || targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(widget.goalId)
          .update({
        'title': titleController.text.trim(),
        'target': double.parse(targetController.text),
        'timeFrame': selectedTime,
      });

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Header Background
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

          /// Header UI
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
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Edit Financial Goal",
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

          /// Form Body
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
                  children: [
                    const SizedBox(height: 30),

                    _buildLabel("Goal name"),
                    TextField(
                      controller: titleController,
                      decoration: _inputDecoration("e.g. Dream car"),
                    ),

                    const SizedBox(height: 25),

                    _buildLabel("Target Amount"),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("EGP 10,000"),
                    ),

                    const SizedBox(height: 25),

                    _buildLabel("Time frame"),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: _inputDecoration(""),
                      items: const [
                        DropdownMenuItem(value: "6 months", child: Text("6 months")),
                        DropdownMenuItem(value: "12 months", child: Text("12 months")),
                        DropdownMenuItem(value: "24 months", child: Text("24 months")),
                        DropdownMenuItem(value: "3 years", child: Text("3 years")),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedTime = val!;
                        });
                      },
                    ),

                    const Spacer(),

                    /// Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : updateGoal,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Update Goal",
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 18,
                          ),
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
      ),
    );
  }

  /// ✅ Helper Method for Labels
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// ✅ Helper Method for Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}