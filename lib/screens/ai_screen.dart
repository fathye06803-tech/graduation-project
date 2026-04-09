import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController messageController = TextEditingController();
  bool isLoading = false;

  List<Map<String, dynamic>> messages = [
    {
      "text": "Hi! I'm your Blue Cash assistant. How can I help you manage your goals today?",
      "isUser": false,
    }
  ];

  /// 🔥 Send Message Function
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String userMessage = messageController.text.trim();

    setState(() {
      messages.add({"text": userMessage, "isUser": true});
      isLoading = true;
    });

    messageController.clear();

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

      /// 1. Fetch Goals for Context
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals')
          .get();

      String goalsData = "";
      for (var doc in goalsSnapshot.docs) {
        var d = doc.data();
        goalsData += "- Goal: ${d['title']}, Target: ${d['target']} EGP, Saved: ${d['current']} EGP.\n";
      }

      /// 2. Setup AI with Correct Safety Settings
      // بنخلي الـ Threshold هو 'blockNone' عشان ميقفلش الردود المالية
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
            "You are a helpful financial assistant for 'Blue Cash' app. "
                "Use the user's goal data to provide advice: $goalsData. "
                "Keep your responses short, professional, and friendly."
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        ],
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);

      /// 3. Handle Response safely
      if (mounted) {
        setState(() {
          // هنا بنشيك هل الرد فيه نص فعلاً ولا الـ AI عمل بلوك للـ Candidate
          if (response.text != null && response.text!.isNotEmpty) {
            messages.add({"text": response.text!, "isUser": false});
          } else {
            messages.add({
              "text": "I can't answer this right now. Please try asking about your savings or goals.",
              "isUser": false
            });
          }
          isLoading = false;
        });
      }

    } catch (e) {
      debugPrint("AI Error: $e");
      if (mounted) {
        setState(() {
          messages.add({"text": "Connection issue. Please check your internet or API key.", "isUser": false});
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 20),
                      Text("Smart Assistant", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SvgPicture.asset("assets/icon/ai logo.svg", width: 70, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              ],
            ),
          ),

          /// Chat Body
          Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        bool isUser = messages[index]["isUser"];
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser ? AppColors.blue : const Color(0xff9FB5D8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              messages[index]["text"],
                              style:
                              TextStyle(color: isUser ? Colors.white : AppColors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLoading) const Padding(padding: EdgeInsets.only(bottom: 10),
                      child: CircularProgressIndicator(color: AppColors.blue)),

                  /// Input Field
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: const Color(0xff9FB5D8),
                          borderRadius: BorderRadius.circular(40)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              onSubmitted: (_) => sendMessage(),
                              decoration: const InputDecoration(
                                  hintText: "Type your message...",
                                  border: InputBorder.none),
                            ),
                          ),
                          IconButton(
                            icon: SvgPicture.asset("assets/icon/send.svg",
                                width: 26,
                                colorFilter: const ColorFilter.mode(AppColors.blue, BlendMode.srcIn)),
                            onPressed: isLoading ? null : sendMessage,
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