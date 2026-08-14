import 'package:flutter/material.dart';

class CitationBadge extends StatelessWidget {
  final Map<String, dynamic> citations;
  final double confidenceScore;
  final bool isVerified;

  const CitationBadge({
    Key? key,
    required this.citations,
    required this.confidenceScore,
    required this.isVerified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification status
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.warning_amber,
                color: isVerified ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isVerified ? 'Verified Sources' : 'Unverified',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const Spacer(),
              // Confidence score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getConfidenceColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confidenceScore * 100).toInt()}% Confidence',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getConfidenceColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Citations list
          if (citations['quran'] != null && (citations['quran'] as List).isNotEmpty)
            _buildCitationSection('📖 Quran', citations['quran'] as List),
          if (citations['hadith'] != null && (citations['hadith'] as List).isNotEmpty)
            _buildCitationSection('📜 Hadith', citations['hadith'] as List),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (confidenceScore > 0.8) return Colors.green;
    if (confidenceScore > 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCitationSection(String title, List<dynamic> refs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: refs.map((ref) {
            return Chip(
              label: Text(
                ref['raw'] ?? ref.toString(),
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: Colors.blue.shade50,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }
}