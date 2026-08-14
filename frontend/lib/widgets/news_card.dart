import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/models/news.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

class NewsCard extends StatelessWidget {
  final News news;

  const NewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (news.url != null && news.url!.isNotEmpty) {
            _launchUrl(news.url!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (news.image != null && news.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildImage(news.image!),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E90FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          news.source,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E90FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(news.addedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (news.url != null && news.url!.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          'Read More',
                          style: TextStyle(
                            color: Color(0xFF1E90FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFF1E90FF),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String hexString) {
    try {
      // Convert hex to bytes and then to Uint8List
      List<int> byteList = _hexToBytes(hexString);
      Uint8List bytes = Uint8List.fromList(byteList);
      
      return Image.memory(
        bytes,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 180,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48),
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 7) {
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTime;
    }
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      if (i + 2 <= hex.length) {
        try {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        } catch (e) {
          // Skip invalid hex
        }
      }
    }
    return bytes;
  }
}