import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blue_cash/core/theme/app_color.dart';

class FinancialManagementScreen extends StatefulWidget {
  const FinancialManagementScreen({super.key});

  @override
  State<FinancialManagementScreen> createState() => _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen> {
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController expenseTitleController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  void _loadFinancialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!['salary'] != null) {
        salaryController.text = doc.data()!['salary'].toString();
      }
    }
  }

  Future<void> _updateSalary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double salary = double.tryParse(salaryController.text) ?? 0.0;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'salary': salary,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salary Updated!")));
    }
  }

  Future<void> _addFixedExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String title = expenseTitleController.text.trim();
    double amount = double.tryParse(expenseAmountController.text) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid title and amount")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1. Fetch Salary, current expenses and monthly deposits to calculate Remaining
      var userDoc = await userRef.get();
      var expensesSnapshot = await userRef.collection('fixed_expenses').get();
      var goalsSnapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('members', arrayContains: user.uid)
          .get();

      double currentSalary = (userDoc.data()?['salary'] ?? 0).toDouble();

      // Calculate current total expenses
      double totalFixedExpenses = 0;
      for (var exp in expensesSnapshot.docs) {
        totalFixedExpenses += (exp.data()['amount'] ?? 0).toDouble();
      }

      // Calculate current month deposits in goals
      double currentMonthContributions = 0;
      DateTime now = DateTime.now();
      for (var goalDoc in goalsSnapshot.docs) {
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

      // Calculate actual Remaining balance
      double remainingSalary = currentSalary - totalFixedExpenses - currentMonthContributions;

      // 2. Condition Check: Is new expense amount > Remaining balance?
      if (amount > remainingSalary) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Cannot add expense! Only EGP ${remainingSalary.toStringAsFixed(0)} remaining."),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      // 3. If valid, proceed to add
      await userRef.collection('fixed_expenses').add({
        'title': title,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      expenseTitleController.clear();
      expenseAmountController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense Added Successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error adding expense: $e");
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
                        "Financial Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Monthly Salary"),
                          TextField(
                            controller: salaryController,
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("Enter salary").copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check_circle, color: AppColors.blue),
                                onPressed: _updateSalary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildLabel("Add Expense"),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: expenseTitleController,
                                  decoration: _inputStyle("Title"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: expenseAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputStyle("EGP"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _addFixedExpense,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                isLoading ? "Checking..." : "Add Expense",
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          _buildLabel("Expenses List"),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('fixed_expenses')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              if (snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Text("No expenses added.", style: TextStyle(color: Colors.grey.shade500)),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var doc = snapshot.data!.docs[index];
                                  var data = doc.data() as Map<String, dynamic>;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['title'] ?? "",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blue),
                                            ),
                                            const SizedBox(height: 4),
                                            Text("Fixed Expense", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "- EGP ${data['amount']}",
                                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                                              onPressed: () => doc.reference.delete(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
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