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
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> saveMessage(String text, bool isUser) async {
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .add({
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String userMessage = messageController.text.trim();
    messageController.clear();
    setState(() => isLoading = true);

    await saveMessage(userMessage, true);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);
      final botResponse = response.text ?? "I'm sorry, I couldn't process that.";

      await saveMessage(botResponse, false);
    } catch (e) {
      await saveMessage("Connection error. Please try again.", false);
    } finally {
      setState(() => isLoading = false);
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.blue),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "AI Assistant",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
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
                          .doc(uid)
                          .collection('chats')
                          .orderBy('timestamp', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        var docs = snapshot.data!.docs;
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var data = docs[index].data() as Map<String, dynamic>;
                            bool isUser = data['isUser'] ?? false;
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.blue : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                    )
                                  ],
                                ),
                                child: Text(
                                  data['text'] ?? "",
                                  style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Ask anything...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, color: AppColors.blue),
                        onPressed: isLoading ? null : sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}