import 'package:flutter/material.dart';
import 'package:blue_cash/core/theme/app_color.dart';
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
  bool showInvestmentRanges = false;

  static const String _fallbackMessage =
      "This feature will be added in the next update. Stay tuned!";

  static const List<String> _quickQuestions = [
    "Where can I invest my extra savings?",
    "Can I share a saving goal with someone?",
    "Am I saving more than last month?",
  ];

  static const Map<String, String> _investmentSuggestionsByRange = {
    "EGP 500 - 2,000":
    "Great start. Focus on low-risk options:\n"
        "• Emergency fund first (1-2 months of expenses)\n"
        "• High-yield savings account or bank certificate\n"
        "• Gold savings plan in small monthly amounts\n\n"
        "Keep it simple and consistent every month.",
    "EGP 2,000 - 10,000":
    "You can diversify your savings:\n"
        "• 50% stable savings/certificates\n"
        "• 30% low-to-medium risk mutual funds\n"
        "• 20% long-term goals (education, business skill, or index exposure)\n\n"
        "Diversification helps reduce risk while improving returns.",
    "EGP 10,000+":
    "You have room for a stronger investment mix:\n"
        "• Build a full emergency fund first (3-6 months)\n"
        "• Diversify across certificates, funds, and long-term assets\n"
        "• Consider periodic investing (monthly) instead of one-time timing\n\n"
        "For larger amounts, a licensed financial advisor is recommended.",
  };

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
    await saveMessage(_fallbackMessage, false);

    if (mounted) {
      setState(() {
        isLoading = false;
        showInvestmentRanges = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> onQuickQuestionTap(String question) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    await saveMessage(question, true);

    String response;
    bool shouldShowRanges = false;

    if (question == _quickQuestions[0]) {
      response =
      "Smart move. I can suggest investment options based on your savings range.\n"
          "Choose your current range:";
      shouldShowRanges = true;
    } else if (question == _quickQuestions[1]) {
      response =
      "Yes, you can share a goal with someone depending on your goal settings and agreement. "
          "Choose a shared goal, define each member's contribution, and track progress together.";
    } else if (question == _quickQuestions[2]) {
      response = await _buildSavingsComparisonReply();
    } else {
      response = _fallbackMessage;
    }

    await saveMessage(response, false);
    if (mounted) {
      setState(() {
        isLoading = false;
        showInvestmentRanges = shouldShowRanges;
      });
    }
    _scrollToBottom();
  }

  Future<void> onInvestmentRangeTap(String range) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    await saveMessage(range, true);
    await saveMessage(
      _investmentSuggestionsByRange[range] ?? _fallbackMessage,
      false,
    );
    if (mounted) {
      setState(() {
        isLoading = false;
        showInvestmentRanges = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _buildSavingsComparisonReply() async {
    if (uid.isEmpty) {
      return "Please login first to compare your monthly savings.";
    }

    final now = DateTime.now();
    final startCurrentMonth = DateTime(now.year, now.month, 1);
    final startNextMonth = DateTime(now.year, now.month + 1, 1);
    final startPreviousMonth = DateTime(now.year, now.month - 1, 1);

    final depositsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('deposits')
        .where('userId', isEqualTo: uid)
        .where(
      'date',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startPreviousMonth),
    )
        .where(
      'date',
      isLessThan: Timestamp.fromDate(startNextMonth),
    )
        .get();

    double previousMonthSavings = 0;
    double currentMonthSavings = 0;

    for (final doc in depositsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final timestamp = data['date'];
      if (timestamp is! Timestamp) continue;

      final depositDate = timestamp.toDate();
      if (depositDate.year == startCurrentMonth.year &&
          depositDate.month == startCurrentMonth.month) {
        currentMonthSavings += amount;
      } else if (depositDate.year == startPreviousMonth.year &&
          depositDate.month == startPreviousMonth.month) {
        previousMonthSavings += amount;
      }
    }

    if (currentMonthSavings == 0 && previousMonthSavings == 0) {
      return "I could not find savings records for this month or last month yet. Add deposits first, then I can compare accurately.";
    }

    final diff = currentMonthSavings - previousMonthSavings;
    final currentText = currentMonthSavings.toStringAsFixed(0);
    final previousText = previousMonthSavings.toStringAsFixed(0);
    final diffText = diff.abs().toStringAsFixed(0);

    if (previousMonthSavings == 0 && currentMonthSavings > 0) {
      return "Great start! You saved EGP $currentText this month, while last month was EGP 0.\n"
          "You are building a strong saving habit.";
    }

    if (currentMonthSavings > previousMonthSavings) {
      return "Excellent progress! You saved more this month.\n"
          "This month: EGP $currentText\n"
          "Last month: EGP $previousText\n"
          "Increase: EGP $diffText";
    }

    if (currentMonthSavings < previousMonthSavings) {
      return "You're still saving, but slightly less than last month.\n"
          "This month: EGP $currentText\n"
          "Last month: EGP $previousText\n"
          "Difference: EGP $diffText less";
    }

    return "Nice consistency. Your savings are stable across both months.\n"
        "This month: EGP $currentText\n"
        "Last month: EGP $previousText";
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header Gradient (Matching My Goals)
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
            child: Column(
              children: [
                // Top Title Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Text(
                        "AI Assistant",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Chat Area White Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
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

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  "Choose a quick question to get started.",
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var data = docs[index].data() as Map<String, dynamic>;
                            bool isUser = data['isUser'] ?? false;
                            return _buildChatBubble(data['text'] ?? "", isUser);
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Input Field Section
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = _quickQuestions[index];
                return ActionChip(
                  label: Text(question, style: const TextStyle(fontSize: 12)),
                  onPressed: isLoading ? null : () => onQuickQuestionTap(question),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                );
              },
            ),
          ),
          if (showInvestmentRanges) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _investmentSuggestionsByRange.keys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final range = _investmentSuggestionsByRange.keys.elementAt(index);
                  return ActionChip(
                    label: Text(range, style: const TextStyle(fontSize: 12)),
                    onPressed: isLoading ? null : () => onInvestmentRangeTap(range),
                    backgroundColor: AppColors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.blue.withOpacity(0.25)),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isLoading ? null : sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}