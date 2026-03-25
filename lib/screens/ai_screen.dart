import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {

  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [
    {
      "text": "Hi Fathy 👋",
      "isUser": false,
    },
    {
      "text": "How can I help you with your savings today?",
      "isUser": false,
    }
  ];

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "text": messageController.text,
        "isUser": true,
      });
    });

    messageController.clear();

    /// رد مؤقت من AI
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add({
          "text": "I'm analyzing your savings request...",
          "isUser": false,
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// Blue Header
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

          /// Header
          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [

                      /// Back Button SVG
                      IconButton(
                        icon: SvgPicture.asset(
                          "assets/icon/back.svg",
                          color: Colors.white,
                          width: 24,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(width: 20),

                      const Text(
                        "Smart Financial Assistant",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// AI Logo SVG
                SvgPicture.asset(
                  "assets/icon/ai logo.svg",
                  width: 70,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          /// Chat Body
          Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),

              child: Column(
                children: [

                  const SizedBox(height: 20),

                  /// Messages
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {

                        bool isUser = messages[index]["isUser"];

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,

                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),

                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.blue
                                  : const Color(0xff9FB5D8),

                              borderRadius: BorderRadius.circular(14),
                            ),

                            child: Text(
                              messages[index]["text"],
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// Input
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xff9FB5D8),
                        borderRadius: BorderRadius.circular(40),
                      ),

                      child: Row(
                        children: [

                          /// TextField
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(
                                hintText: "Type your message...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          /// Send SVG
                          IconButton(
                            icon: SvgPicture.asset(
                              "assets/icon/send.svg",
                              width: 26,
                              color: AppColors.orange,
                            ),
                            onPressed: sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}