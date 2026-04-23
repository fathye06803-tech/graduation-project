import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({super.key});

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Savings & Expenses",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
              child: user == null
                  ? const Center(child: Text("Please login first"))
                  : StreamBuilder<List<QueryDocumentSnapshot>>(
                stream: CombineLatestStream.list([
                  FirebaseFirestore.instance
                      .collectionGroup('deposits')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('fixed_expenses')
                      .snapshots(),
                ]).map((list) => list[0].docs + list[1].docs),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Synchronizing data... Please wait a moment.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  var allDocs = snapshot.data!;

                  allDocs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;

                    Timestamp t1 = dataA['date'] ?? dataA['createdAt'] ?? Timestamp.now();
                    Timestamp t2 = dataB['date'] ?? dataB['createdAt'] ?? Timestamp.now();

                    return t2.compareTo(t1);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    itemCount: allDocs.length,
                    itemBuilder: (context, index) {
                      var data = allDocs[index].data() as Map<String, dynamic>;

                      bool isDeposit = data.containsKey('goalName');

                      double amount = (data['amount'] as num?)?.toDouble() ?? 0;
                      int colorValue = isDeposit
                          ? (data['color'] ?? AppColors.blue.value)
                          : Colors.red.value;

                      String title = isDeposit
                          ? data['goalName']
                          : (data['title'] ?? "Fixed Expense");

                      Timestamp ts = data['date'] ?? data['createdAt'] ?? Timestamp.now();
                      DateTime date = ts.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: Color(colorValue), width: 5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(colorValue).withOpacity(0.1),
                                  child: Icon(
                                    isDeposit ? Icons.savings : Icons.money_off,
                                    color: Color(colorValue),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${date.day}/${date.month}/${date.year}",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              isDeposit ? "+ EGP ${amount.toStringAsFixed(0)}" : "- EGP ${amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? Colors.green : Colors.red,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("No transactions", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}