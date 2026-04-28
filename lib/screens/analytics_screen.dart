import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Map<String, Color> categoryColors = {
    "Food": Colors.orange,
    "Transport": Colors.blue,
    "Rent": Colors.purple,
    "Health": Colors.red,
    "Entertainment": Colors.pink,
    "Shopping": Colors.teal,
    "Others": Colors.grey,
  };

  Color _getCategoryColor(String category, int index) {
    if (categoryColors.containsKey(category)) {
      return categoryColors[category]!;
    }
    List<Color> dynamicColors = [Colors.indigo, Colors.amber, Colors.cyan, Colors.brown];
    return dynamicColors[index % dynamicColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Header Gradient (نفس استايل Edit Goal)
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
                // 2. Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Financial Analytics",
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
                // 3. Main Content Container
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('fixed_expenses')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Grouping logic
                        Map<String, List<QueryDocumentSnapshot>> groupedData = {};
                        for (var doc in snapshot.data!.docs) {
                          DateTime date = (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          String monthKey = DateFormat('MMMM yyyy').format(date);
                          if (groupedData[monthKey] == null) groupedData[monthKey] = [];
                          groupedData[monthKey]!.add(doc);
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                          children: groupedData.entries.map((entry) {
                            return _buildMonthlyCard(entry.key, entry.value);
                          }).toList(),
                        );
                      },
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

  Widget _buildMonthlyCard(String monthTitle, List<QueryDocumentSnapshot> docs) {
    Map<String, double> categoriesMap = {};
    double totalSpentThisMonth = 0;

    for (var doc in docs) {
      String cat = doc['category'] ?? "Others";
      double amt = (doc['amount'] ?? 0).toDouble();
      categoriesMap[cat] = (categoriesMap[cat] ?? 0) + amt;
      totalSpentThisMonth += amt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            monthTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blue),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(thickness: 0.8),
          ),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: _buildSections(categoriesMap, totalSpentThisMonth),
              ),
            ),
          ),
          const SizedBox(height: 25),
          _buildDetailedLegend(categoriesMap, totalSpentThisMonth),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(thickness: 0.8),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Monthly Spending", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
              Text(
                "EGP ${totalSpentThisMonth.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 17),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data, double total) {
    int index = 0;
    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getCategoryColor(entry.key, index);
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildDetailedLegend(Map<String, double> data, double total) {
    int index = 0;
    return Column(
      children: data.entries.map((entry) {
        final color = _getCategoryColor(entry.key, index);
        index++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                "EGP ${entry.value.toStringAsFixed(0)}",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No analytics available yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}