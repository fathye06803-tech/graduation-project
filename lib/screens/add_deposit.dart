import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
class AddDepositScreen extends StatefulWidget {

  final String goalName;

  const AddDepositScreen({super.key, required this.goalName});

  @override
  State<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends State<AddDepositScreen> {

  final TextEditingController amountController = TextEditingController();

  DateTime? selectedDate;

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
                    "Add Deposit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
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

              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height:20),

                    /// Goal Name
                    Text(
                      widget.goalName,
                      style: const TextStyle(
                        fontSize:22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),

                    const SizedBox(height:30),

                    /// Amount Label
                    const Text(
                      "Deposit Amount",
                      style: TextStyle(
                        fontSize:16,
                        color: AppColors.blue,
                      ),
                    ),

                    const SizedBox(height:10),

                    /// Amount Field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "\$ 100",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height:25),

                    /// Date Label
                    const Text(
                      "Date",
                      style: TextStyle(
                        fontSize:16,
                        color: AppColors.blue,
                      ),
                    ),

                    const SizedBox(height:10),

                    /// Date Picker
                    GestureDetector(
                      onTap: () async {

                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );

                        if(picked != null){
                          setState(() {
                            selectedDate = picked;
                          });
                        }

                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal:16,
                          vertical:18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height:55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {

                        },
                        child: const Text(
                          "Confirm Deposit",
                          style: TextStyle(
                            fontSize:18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height:20),

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