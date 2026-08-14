import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/models/post.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool showActions;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.showActions = false,
    this.onDelete,
  });

  /// Parse image string — handles data URI, plain base64, or URL
  Widget _buildImageWidget(String imageData, double aspectRatio) {
    String? url;
    Uint8List? memoryBytes;

    if (imageData.startsWith('data:')) {
      // Data URI: data:image/jpeg;base64,/9j/4AAQ...
      url = imageData;
    } else if (_isBase64(imageData)) {
      // Plain base64 string
      try {
        memoryBytes = base64Decode(imageData);
      } catch (_) {
        memoryBytes = null;
      }
    } else {
      // Regular URL or path
      url = imageData;
      if (!url.startsWith('http')) {
        // Prepend backend base URL if relative path
        url = 'http://YOUR_BACKEND_URL$url';
      }
    }

    // Use AspectRatio for Instagram-style container
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        width: double.infinity,
        color: Colors.grey[100],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url != null
              ? (url.startsWith('data:')
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => _errorWidget(),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                      placeholder: (context, url) => _loadingWidget(),
                      errorWidget: (context, url, error) => _errorWidget(),
                    ))
              : (memoryBytes != null
                  ? Image.memory(
                      memoryBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => _errorWidget(),
                    )
                  : _errorWidget()),
        ),
      ),
    );
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _loadingWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine aspect ratio from post metadata
    final ratio = post.imageRatio ?? 'portrait';
    final aspectRatio = ratio == 'square' ? 1.0 : 4.0 / 5.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: post.isOfficial
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  child: Text(
                    post.addedBy.isNotEmpty ? post.addedBy[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: post.isOfficial ? Colors.green : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.addedBy,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (post.isOfficial)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Official',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _formatDate(post.addedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActions && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            if (post.text.isNotEmpty)
              Text(
                post.text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 8),

            // Instagram-style Image
            if (post.image != null && post.image!.isNotEmpty)
              _buildImageWidget(post.image!, aspectRatio),

            // Video placeholder
            if (post.video != null && post.video!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_outline, size: 64),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}