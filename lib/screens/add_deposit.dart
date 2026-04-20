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
  DateTime? selectedDate;
  bool isLoading = false;

  Future<void> addDeposit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    if (amountController.text.isEmpty || selectedDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter amount and date")),
      );
      return;
    }

    final double amount = double.tryParse(amountController.text.trim()) ?? 0.0;

    setState(() => isLoading = true);

    try {
      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(widget.goalId);

      // 1. Fetch current goal data to check limits
      final goalSnapshot = await goalRef.get();

      if (goalSnapshot.exists) {
        final data = goalSnapshot.data()!;
        final double target = (data['target'] ?? 0.0).toDouble();
        final double current = (data['current'] ?? 0.0).toDouble();
        final double remaining = target - current;

        // 2. Validation: Check if entered amount exceeds remaining target
        if (amount > remaining) {
          if (!mounted) return;
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Amount exceeds target! Remaining needed: EGP ${remaining.toStringAsFixed(2)}"),
              backgroundColor: Colors.red,
            ),
          );
          return; // Stop the process
        }
      }

      // 3. Update the goal's current amount
      await goalRef.update({
        'current': FieldValue.increment(amount),
      });

      // 4. Add the deposit record
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('deposits')
          .add({
        'goalId': widget.goalId,
        'goalName': widget.goalName,
        'amount': amount,
        'date': Timestamp.fromDate(selectedDate!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deposit added successfully")),
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
                      "Add New Deposit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Saving for: ${widget.goalName}",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Amount", style: TextStyle(color: AppColors.blue, fontSize: 16)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              // Trigger rebuild to update button state
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: "Enter amount",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("Date", style: TextStyle(color: AppColors.blue, fontSize: 16)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? "Select Date"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                  ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              // Logic to disable the button if fields are empty or loading
                              onPressed: (isLoading || amountController.text.isEmpty || selectedDate == null)
                                  ? null
                                  : addDeposit,
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                "Confirm Deposit",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
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
}