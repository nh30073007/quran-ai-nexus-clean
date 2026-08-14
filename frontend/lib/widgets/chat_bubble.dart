import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar('AI', const Color(0xFF1E90FF)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF1E90FF)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 16 : 4),
                      topRight: Radius.circular(message.isUser ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFF1E90FF).withOpacity(0.3),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agent badge
                      if (!message.isUser && message.agentName != null)
                        _buildAgentBadge(message.agentName!),
                      
                      // Verse reference badge
                      if (message.verseReference != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, top: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '📖 ${message.verseReference}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      
                      // Main content
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Timestamp
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Citation badge
                if (!message.isUser && message.citations != null && message.citations!.isNotEmpty)
                  _buildCitationBadge(context),
                
                // Confidence badge
                if (!message.isUser && message.confidenceScore != null)
                  _buildConfidenceBadge(context),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(
              'You',
              Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentBadge(String agentName) {
    String displayName = agentName
        .replaceAll('_agent', '')
        .replaceAll('_', ' ')
        .toUpperCase();
    
    Map<String, Color> agentColors = {
      'TAFSIR': Colors.purple,
      'SPIRITUAL': Colors.teal,
      'FIQH': Colors.indigo,
      'HADITH': Colors.brown,
      'GENERAL': Colors.blue,
      'WELCOME': Colors.green,
      'ERROR': Colors.red,
    };
    
    Color color = agentColors[displayName] ?? Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '🤖 $displayName AGENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCitationBadge(BuildContext context) {
    final citations = message.citations!;
    final quranCites = citations.where((c) => c['type'] == 'quran').toList();
    final hadithCites = citations.where((c) => c['type'] == 'hadith').toList();
    final total = quranCites.length + hadithCites.length;
    
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6, left: 4, right: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (message.isVerified == true)
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (message.isVerified == true)
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (message.isVerified == true)
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                color: (message.isVerified == true)
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                (message.isVerified == true) ? 'Verified Sources' : 'Check Sources',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: (message.isVerified == true)
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (quranCites.isNotEmpty)
            _buildCitationSection('📖 Quran', quranCites, Colors.green),
          if (hadithCites.isNotEmpty)
            _buildCitationSection('📜 Hadith', hadithCites, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildCitationSection(String title, List<dynamic> refs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: refs.map((ref) {
            final sourceRef = ref['source_ref'] ?? ref['raw'] ?? ref.toString();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                sourceRef,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildConfidenceBadge(BuildContext context) {
    final score = message.confidenceScore ?? 0.0;
    Color scoreColor;
    String label;
    
    if (score >= 0.8) {
      scoreColor = Colors.green;
      label = 'High Confidence';
    } else if (score >= 0.5) {
      scoreColor = Colors.orange;
      label = 'Medium Confidence';
    } else {
      scoreColor = Colors.red;
      label = 'Low Confidence';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label • ${(score * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: scoreColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String label, Color color) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final time = DateTime.parse(timestamp);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}