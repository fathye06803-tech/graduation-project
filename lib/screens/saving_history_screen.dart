import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      body: Stack(
        children: [
          /// Header Background
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

          /// Header UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // أضفت IconButton للرجوع إذا كنت تتنقل لهذه الشاشة من مكان آخر
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Text(
                    "Savings History",
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

          /// History List Container
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
                  : StreamBuilder<QuerySnapshot>(
                // الـ Stream ده هيتحدث تلقائياً أول ما تمسح Goal من الشاشة التانية
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('deposits')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("💰", style: TextStyle(fontSize: 50)),
                          SizedBox(height: 10),
                          Text("No deposits yet",
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;

                      String goalName = data['goalName'] ?? "General Savings";
                      double amount = (data['amount'] as num?)?.toDouble() ?? 0;

                      // معالجة التاريخ بأمان
                      DateTime date;
                      if (data['date'] is Timestamp) {
                        date = (data['date'] as Timestamp).toDate();
                      } else {
                        date = DateTime.now();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goalName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${date.day}/${date.month}/${date.year}",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            Text(
                              "+ EGP ${amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
}