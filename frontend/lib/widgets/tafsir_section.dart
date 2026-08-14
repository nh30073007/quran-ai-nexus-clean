import 'package:flutter/material.dart';

class TafsirSection extends StatefulWidget {
  final Map<String, dynamic> verse;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TafsirSection({
    super.key,
    required this.verse,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<TafsirSection> createState() => _TafsirSectionState();
}

class _TafsirSectionState extends State<TafsirSection> {
  bool _isLoading = false;
  Map<String, dynamic>? _tafsirData;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    if (widget.verse['tafsir'] != null) {
      setState(() {
        _tafsirData = widget.verse['tafsir'];
      });
      return;
    }
    // If tafsir not available, show placeholder
    setState(() {
      _tafsirData = {
        'ibn_kathir': 'Tafsir not available for this verse.',
        'jalalayn': 'Tafsir not available for this verse.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.brown.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            onTap: widget.onToggle,
            leading: const Icon(
              Icons.book,
              color: Colors.brown,
            ),
            title: const Text(
              '📚 Tafsir Explanation',
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
          // Content
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tafsirData != null) ...[
                    _buildTafsirItem(
                      'Ibn Kathir',
                      _tafsirData!['ibn_kathir'] ?? 'Not available',
                    ),
                    const SizedBox(height: 12),
                    _buildTafsirItem(
                      'Al-Jalalayn',
                      _tafsirData!['jalalayn'] ?? 'Not available',
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

  Widget _buildTafsirItem(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}