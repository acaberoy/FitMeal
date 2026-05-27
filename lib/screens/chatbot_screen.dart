import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/user_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I am your Premium FitMeal AI Coach. What would you like to know about your meals or workouts today?',
      'isMe': false,
    }
  ];
  bool _isTyping = false;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isMe': true});
      _messageController.clear();
      _isTyping = true;
    });

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String aiResponse = _generateMockResponse(text.toLowerCase(), userProvider);

      setState(() {
        _isTyping = false;
        _messages.add({'text': aiResponse, 'isMe': false});
      });
    });
  }

  String _generateMockResponse(String query, UserProvider provider) {
    if (query.contains('protein') || query.contains('macro')) {
      return 'Based on your ${provider.primaryGoal} goal at ${provider.weight}kg, I recommend focusing on lean proteins like chicken breast or tofu. Aim for about ${provider.weight * 2}g of protein daily!';
    } else if (query.contains('workout') || query.contains('exercise')) {
      return 'You have completed ${provider.workoutsCompleted} workouts so far. Your next recommended session is the "${provider.workouts.isNotEmpty ? provider.workouts.first['name'] : 'Recovery'}" routine. Would you like me to adjust it?';
    } else if (query.contains('calorie') || query.contains('weight')) {
      return 'To hit your ${provider.primaryGoal} target, you should aim for your calculated daily calorie goal. Make sure you log your meals using the "Mark as done" checkmarks on the dashboard so I can track your adherence!';
    } else {
      return 'That\'s a great question! As your AI Coach, I suggest staying consistent with your daily generated plans. Consistency is key to achieving your ${provider.primaryGoal} goal.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text('Premium AI Coach', style: TextStyle(color: AppTheme.textPrimaryColor)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                
                final msg = _messages[index];
                return _buildChatBubble(msg['text'], msg['isMe']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: !isMe ? Border.all(color: AppTheme.accentColor.withOpacity(0.3)) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: const Text(
          'AI is typing...',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Ask about meals or workouts...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
