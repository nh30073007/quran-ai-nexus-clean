import 'package:flutter/material.dart';

class SufiInsight extends StatefulWidget {
  final Map<String, dynamic> verse;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SufiInsight({
    super.key,
    required this.verse,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<SufiInsight> createState() => _SufiInsightState();
}

class _SufiInsightState extends State<SufiInsight> {
  Map<String, dynamic>? _sufiData;

  @override
  void initState() {
    super.initState();
    _loadSufiData();
  }

  void _loadSufiData() {
    if (widget.verse['sufi'] != null) {
      setState(() {
        _sufiData = widget.verse['sufi'];
      });
    } else {
      setState(() {
        _sufiData = {
          'rumi': 'Sufi insights not available for this verse.',
          'ibn_arabi': 'Sufi insights not available for this verse.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: widget.onToggle,
            leading: const Icon(
              Icons.psychology,
              color: Colors.deepPurple,
            ),
            title: const Text(
              '✨ Sufi Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              widget.isExpanded
                  ? Icons.expand_less
                  : Icons.expand_more,
            ),
          ),
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sufiData != null) ...[
                    _buildInsightCard(
                      'Rumi\'s Wisdom',
                      _sufiData!['rumi'] ?? 'Not available',
                      Icons.auto_stories,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildInsightCard(
                      'Ibn Arabi\'s Perspective',
                      _sufiData!['ibn_arabi'] ?? 'Not available',
                      Icons.lightbulb,
                      Colors.blue,
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}