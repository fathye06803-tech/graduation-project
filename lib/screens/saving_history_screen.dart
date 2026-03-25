import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({super.key});

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {

  /// مؤقتا بيانات Fake
  List<Map<String, dynamic>> deposits = [
    {
      "goal": "Dream Car",
      "amount": 200,
      "date": "12 May 2026"
    },
    {
      "goal": "Travel",
      "amount": 150,
      "date": "5 May 2026"
    },
    {
      "goal": "Laptop",
      "amount": 100,
      "date": "1 May 2026"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Header
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

          /// Back + Title
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
                      height: 24,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width:20),

                  const Text(
                    "Savings History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Body
          Padding(
            padding: const EdgeInsets.only(top:160),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),

              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: deposits.length,
                itemBuilder: (context, index) {

                  var deposit = deposits[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom:15),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              deposit["goal"],
                              style: const TextStyle(
                                fontSize:18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue,
                              ),
                            ),

                            const SizedBox(height:5),

                            Text(
                              deposit["date"],
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          "\$${deposit["amount"]}",
                          style: const TextStyle(
                            fontSize:18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )

                      ],
                    ),
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