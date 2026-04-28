import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:blue_cash/screens/edit_profile_screen.dart';
import 'package:blue_cash/screens/login_screen.dart';
import 'package:blue_cash/screens/financial_management_screen.dart';
import 'package:blue_cash/screens/analytics_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  double totalSavings = 0;
  double salary = 0;
  double remainingSalary = 0;
  int goalsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      var expensesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fixed_expenses')
          .get();

      var goalsSnapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('members', arrayContains: user.uid)
          .get();

      DateTime now = DateTime.now();
      double currentMonthContributions = 0;
      double allTimeSavings = 0;

      for (var goalDoc in goalsSnapshot.docs) {
        var depositsSnapshot = await goalDoc.reference
            .collection('deposits')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var deposit in depositsSnapshot.docs) {
          var data = deposit.data();
          double amt = (data['amount'] ?? 0).toDouble();
          allTimeSavings += amt;

          if (data['date'] != null) {
            DateTime depositDate = (data['date'] as Timestamp).toDate();
            if (depositDate.month == now.month && depositDate.year == now.year) {
              currentMonthContributions += amt;
            }
          }
        }
      }

      double currentSalary = (userDoc.data()?['salary'] ?? 0).toDouble();
      double totalFixedExpenses = 0;
      for (var exp in expensesSnapshot.docs) {
        totalFixedExpenses += (exp.data()['amount'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          name = userDoc.data()?['name'] ?? user.displayName ?? user.email?.split('@')[0] ?? "User";
          email = user.email ?? "";
          goalsCount = goalsSnapshot.docs.length;
          totalSavings = allTimeSavings;
          salary = currentSalary;
          remainingSalary = currentSalary - totalFixedExpenses - currentMonthContributions;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Profile",
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.blue.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildStatCard("Salary", salary),
                          const SizedBox(width: 15),
                          _buildStatCard("Remaining", remainingSalary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildStatCard("Savings", totalSavings),
                          const SizedBox(width: 15),
                          _buildStatCard("Goals", goalsCount.toDouble(), isCount: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.blue,
                        size: 24,
                      ),
                      title: const Text("Financial Management"),
                      subtitle: const Text("Salary, Expenses"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FinancialManagementScreen(),
                          ),
                        );
                        fetchProfileData();
                      },
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.pie_chart_outline_rounded,
                        color: AppColors.blue,
                        size: 24,
                      ),
                      title: const Text("Financial Analytics"),
                      subtitle: const Text("Spending & Savings Charts"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: SvgPicture.asset(
                        'assets/icon/edit.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(AppColors.blue, BlendMode.srcIn),
                      ),
                      title: const Text("Edit Profile"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(name: name, email: email),
                          ),
                        );
                        fetchProfileData();
                      },
                    ),

                    ListTile(
                      leading: SvgPicture.asset(
                        'assets/icon/logout.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                      ),
                      title: const Text("Logout"),
                      onTap: () {
                        _showLogoutDialog(context);
                      },
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

  Widget _buildStatCard(String label, double value, {bool isCount = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              isCount ? value.toInt().toString() : "EGP ${value.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}