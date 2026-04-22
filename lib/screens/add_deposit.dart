import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDepositScreen extends StatefulWidget {
  final String goalName;
  final String goalId;

  const AddDepositScreen({
    super.key,
    required this.goalName,
    required this.goalId,
  });

  @override
  State<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends State<AddDepositScreen> {
  final TextEditingController amountController = TextEditingController();
  DateTime? selectedDate = DateTime.now();
  bool isLoading = false;

  final List<Color> contributionColors = [
    AppColors.blue,
    Colors.redAccent,
    Colors.green,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  Color selectedColor = AppColors.blue;

  Future<void> addDeposit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final double amount = double.tryParse(amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String safeName = user.displayName ?? user.email?.split('@')[0] ?? "User";

      final goalRef = FirebaseFirestore.instance.collection('goals').doc(widget.goalId);
      final goalSnapshot = await goalRef.get();

      if (goalSnapshot.exists) {
        final data = goalSnapshot.data()!;
        final double target = (data['target'] ?? 0.0).toDouble();
        final double current = (data['current'] ?? 0.0).toDouble();
        final double remaining = target - current;

        if (amount > remaining) {
          if (!mounted) return;
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Amount exceeds target! Remaining: EGP ${remaining.toStringAsFixed(2)}"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // 1. تحديث المبلغ الحالي في الهدف الرئيسي
      await goalRef.update({
        'current': FieldValue.increment(amount),
      });

      // 2. إضافة سجل الإيداع في المجموعة الفرعية (المعدل)
      await goalRef.collection('deposits').add({
        'amount': amount,
        'userId': user.uid,
        'userName': safeName,
        'goalName': widget.goalName,
        'color': selectedColor.value,
        'date': Timestamp.fromDate(selectedDate ?? DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deposit added successfully!")),
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
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.blue),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Add Contribution",
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Goal: ${widget.goalName}",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Amount (EGP)"),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {}),
                            decoration: _inputStyle("Enter your contribution"),
                          ),
                          const SizedBox(height: 25),
                          _buildFieldLabel("Choose Your Contribution Color"),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 45,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: contributionColors.length,
                              itemBuilder: (context, index) {
                                final color = contributionColors[index];
                                return GestureDetector(
                                  onTap: () => setState(() => selectedColor = color),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 15),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color ? Colors.black : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: selectedColor == color
                                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildFieldLabel("Contribution Date"),
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Text("${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today, size: 20, color: AppColors.blue),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: (isLoading || amountController.text.isEmpty) ? null : addDeposit,
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Confirm Contribution", style: TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}