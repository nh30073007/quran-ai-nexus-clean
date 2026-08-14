import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/models/chat_message.dart';
import 'package:quran_ai_nexus/widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      content: 'Assalamu alaykum! 😊\n\nI am your Quranic AI companion. Ask me anything about the Quran, tafsir, spiritual guidance, or Islamic knowledge.',
      isUser: false,
      timestamp: DateTime.now().toIso8601String(),
      agentName: 'general',
      intent: 'welcome',
    ));
  }

  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage.fromUser(query));
      _controller.clear();
      _isLoading = true;
    });

    try {
      // Send to chat API with history
      final history = _messages
          .where((m) => m.content.isNotEmpty && m.agentName != 'welcome')
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await ApiService.chatQuran(query, history: history);
      print('📥 Chat Response: $response');

      // Extract data safely
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final text = data['text'] ?? data['content'] ?? 'No response received.';

      // Create agent message
      final botMessage = ChatMessage.fromAgent(
        text: text,
        data: data,
      );

      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Chat Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          content: '❌ Error: ${e.toString().replaceFirst('Exception: ', '')}',
          isUser: false,
          timestamp: DateTime.now().toIso8601String(),
          agentName: 'error',
          intent: 'error',
          confidenceScore: 0.0,
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Quran'),
        backgroundColor: const Color(0xFF1E90FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  content: 'Assalamu alaykum! 😊\n\nI am your Quranic AI companion. Ask me anything about the Quran, tafsir, spiritual guidance, or Islamic knowledge.',
                  isUser: false,
                  timestamp: DateTime.now().toIso8601String(),
                  agentName: 'general',
                  intent: 'welcome',
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          
          // Loading indicator
          if (_isLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E90FF),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Thinking... 🤔',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about Quran, faith, or life...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isLoading ? Colors.grey : const Color(0xFF1E90FF),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}