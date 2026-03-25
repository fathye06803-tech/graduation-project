import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {

  String selectedTime = "12 months";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Background
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

          /// Back Button
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
                  const SizedBox(width: 20),
                  const Text(
                    "Add Financial Goal",
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

          /// White Container
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

                    /// Goal Name
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Goal name",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: AppColors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Dream car",
                        hintStyle: const TextStyle(
                          fontFamily: 'Work_Sans',
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Target Amount
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Target Amount",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: AppColors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "\$ 10.000",
                        hintStyle: const TextStyle(
                          fontFamily: 'Work_Sans',
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Time Frame
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Time frame",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: AppColors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedTime,

                      icon: const SizedBox(), 

                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: "6 months",
                          child: Text("6 months"),
                        ),
                        DropdownMenuItem(
                          value: "12 months",
                          child: Text("12 months"),
                        ),
                        DropdownMenuItem(
                          value: "24 months",
                          child: Text("24 months"),
                        ),
                        DropdownMenuItem(
                          value: "3 years",
                          child: Text("3 years"),
                        ),
                      ],

                      onChanged: (value) {
                        setState(() {
                          selectedTime = value!;
                        });
                      },
                    ),

                    const Spacer(),

                    /// Button
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
                        onPressed: () {},
                        child: const Text(
                          "Amount Deposited",
                          style: TextStyle(
                            fontFamily: 'Work_Sans',
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
}