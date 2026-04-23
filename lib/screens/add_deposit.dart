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
    if (user == null) return;

    final double amount = double.tryParse(amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final goalRef = FirebaseFirestore.instance.collection('goals').doc(widget.goalId);

      var userDoc = await userRef.get();
      var expensesSnapshot = await userRef.collection('fixed_expenses').get();
      var allGoalsSnapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('members', arrayContains: user.uid)
          .get();

      double currentSalary = (userDoc.data()?['salary'] ?? 0).toDouble();
      double totalFixedExpenses = 0;
      for (var exp in expensesSnapshot.docs) {
        totalFixedExpenses += (exp.data()['amount'] ?? 0).toDouble();
      }

      double currentMonthContributions = 0;
      DateTime now = DateTime.now();

      for (var goalDoc in allGoalsSnapshot.docs) {
        var depositsSnapshot = await goalDoc.reference
            .collection('deposits')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var deposit in depositsSnapshot.docs) {
          var depData = deposit.data();
          if (depData['date'] != null) {
            DateTime depositDate = (depData['date'] as Timestamp).toDate();
            if (depositDate.month == now.month && depositDate.year == now.year) {
              currentMonthContributions += (depData['amount'] ?? 0).toDouble();
            }
          }
        }
      }

      double remainingSalary = currentSalary - totalFixedExpenses - currentMonthContributions;

      var goalDocSnapshot = await goalRef.get();
      double targetAmount = (goalDocSnapshot.data()?['target'] ?? 0).toDouble();
      double currentSaved = (goalDocSnapshot.data()?['current'] ?? 0).toDouble();
      double remainingInGoal = targetAmount - currentSaved;

      if (amount > remainingSalary) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Insufficient Salary! Remaining: EGP ${remainingSalary.toStringAsFixed(0)}")),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      if (amount > remainingInGoal) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Amount exceeds Goal target! Remaining: EGP ${remainingInGoal.toStringAsFixed(0)}")),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      String safeName = user.displayName ?? user.email?.split('@')[0] ?? "User";

      await goalRef.update({
        'current': FieldValue.increment(amount),
      });

      await goalRef.collection('deposits').add({
        'amount': amount,
        'userId': user.uid,
        'userName': safeName,
        'goalName': widget.goalName,
        'color': selectedColor.value,
        'date': Timestamp.fromDate(selectedDate ?? DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
        'month': now.month,
        'year': now.year,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deposit added successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
          // Header Gradient (Like My Goals)
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

          // Custom AppBar with Back Button
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
                    "Add Deposit",
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

          // Content Container (White Sheet)
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Goal: ${widget.goalName}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildFieldLabel("Amount (EGP)"),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle("Enter amount"),
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel("Label Color"),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: contributionColors.length,
                        itemBuilder: (context, index) {
                          final color = contributionColors[index];
                          bool isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel("Deposit Date"),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200, // Matches GoalCard color
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: AppColors.blue),
                            const SizedBox(width: 12),
                            Text(
                              "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Main Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: (isLoading) ? null : addDeposit,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Confirm Deposit",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200, // Matches GoalCard style
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}