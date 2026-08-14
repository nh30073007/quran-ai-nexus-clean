import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/widgets/chat_bubble.dart';
import 'package:quran_ai_nexus/models/chat_message.dart';

class AskQuranScreen extends StatefulWidget {
  const AskQuranScreen({super.key});

  @override
  State<AskQuranScreen> createState() => _AskQuranScreenState();
}

class _AskQuranScreenState extends State<AskQuranScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      content: 'Assalamu alaykum! 😊\n\nAsk me anything about the Quran, Tafsir, Fiqh, or spiritual guidance.',
      isUser: false,
      timestamp: DateTime.now().toIso8601String(),
      agentName: 'welcome',
      intent: 'general',
    ));
  }

  Future<void> _askQuran() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage.fromUser(query));
      _queryController.clear();
      _isLoading = true;
    });

    try {
      final result = await ApiService.askQuran(query);
      print('📥 API Response: $result');

      // Extract data safely
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final text = data['text'] ?? 
                    data['content'] ?? 
                    'No response received. Please try again.';

      // Create agent message
      final agentMessage = ChatMessage.fromAgent(
        text: text,
        data: data,
      );

      setState(() {
        _messages.add(agentMessage);
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error: $e');
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
        title: const Text('Ask Quran'),
        backgroundColor: const Color(0xFF1E90FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _messages.clear();
                // Add welcome message again
                _messages.add(ChatMessage(
                  content: 'Assalamu alaykum! 😊\n\nAsk me anything about the Quran, Tafsir, Fiqh, or spiritual guidance.',
                  isUser: false,
                  timestamp: DateTime.now().toIso8601String(),
                  agentName: 'welcome',
                  intent: 'general',
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
                    controller: _queryController,
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
                    onSubmitted: (_) => _askQuran(),
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
                    onPressed: _isLoading ? null : _askQuran,
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
    _queryController.dispose();
    super.dispose();
  }
}