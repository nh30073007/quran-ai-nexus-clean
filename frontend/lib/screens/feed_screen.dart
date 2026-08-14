import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/models/post.dart';
import 'package:quran_ai_nexus/models/news.dart';
import 'package:quran_ai_nexus/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  List<News> _news = [];
  bool _isLoading = true;
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  String? _imageBase64;
  bool _isPosting = false;
  int _selectedTab = 0;

  // Instagram-style ratio: 'square' (1:1) or 'portrait' (4:5)
  String _selectedRatio = 'portrait';

  Map<int, bool> _likedPosts = {};
  Map<int, int> _likeCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final postsData = await ApiService.getPosts();
      final newsData = await ApiService.getNews();
      
      setState(() {
        _posts = postsData.map((json) => Post.fromJson(json)).toList();
        _news = newsData.map((json) => News.fromJson(json)).toList();
        _isLoading = false;
        for (var post in _posts) {
          if (post.id != null) {
            _likeCounts[post.id!] = 0;
            _likedPosts[post.id!] = false;
          }
        }
      });
    } catch (e) {
      print('Load error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Pick image with Instagram-style constraints
  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Only Admin can upload images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    
    // Instagram dimensions
    final maxWidth = _selectedRatio == 'square' ? 1080 : 1080;
    final maxHeight = _selectedRatio == 'square' ? 1080 : 1350;

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: 85,  // Instagram-style compression
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      print('📸 Original image size: ${bytes.length / 1024} KB');
      
      // If still too large (> 1MB), compress more
      var finalBytes = bytes;
      if (bytes.length > 1 * 1024 * 1024) {
        final compressedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: (maxWidth * 0.8).toDouble(),
          maxHeight: (maxHeight * 0.8).toDouble(),
          imageQuality: 75,
        );
        if (compressedFile != null) {
          finalBytes = await compressedFile.readAsBytes();
        }
      }
      
      print('📸 Final image size: ${finalBytes.length / 1024} KB');
      
      final base64String = base64Encode(finalBytes);
      final mimeType = _getMimeType(pickedFile.path);
      
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageBase64 = 'data:$mimeType;base64,$base64String';
      });
    }
  }

  String _getMimeType(String path) {
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Create post with image ratio metadata
  Future<void> _createPost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Only Admin can create posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_postController.text.isEmpty && _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final result = await ApiService.createPostWithMedia(
        text: _postController.text,
        isOfficial: true,
        imageData: _imageBase64,
        imageRatio: _selectedRatio,  // Send ratio to backend
      );

      if (result['message'] != null) {
        _postController.clear();
        setState(() {
          _selectedImage = null;
          _imageBase64 = null;
          _selectedRatio = 'portrait';
        });
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Create post error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isPosting = false);
  }

  void _toggleLike(int postId) {
    setState(() {
      _likedPosts[postId] = !(_likedPosts[postId] ?? false);
      if (_likedPosts[postId] == true) {
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      } else {
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Admin post creation section
          if (isAdmin) 
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF1E90FF),
                        radius: 20,
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          decoration: const InputDecoration(
                            hintText: "Admin: What's on your mind?",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Instagram Ratio Selector
                  Row(
                    children: [
                      const Text(
                        'Aspect Ratio:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      _buildRatioChip('Portrait (4:5)', 'portrait', Icons.crop_portrait),
                      const SizedBox(width: 8),
                      _buildRatioChip('Square (1:1)', 'square', Icons.crop_square),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Photo',
                        color: Colors.green,
                        onTap: _pickImage,
                      ),
                      _buildActionButton(
                        icon: Icons.emoji_emotions,
                        label: 'Feeling',
                        color: Colors.orange,
                        onTap: () {},
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isPosting ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E90FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),  
                          ),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Post', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildMediaPreview(),
                    ),
                ],
              ),
            ),
          
          // User message
          if (!isAdmin)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📢 You are viewing posts. Only Admin can create posts.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabButton('Feed', 0),
                _buildTabButton('News', 1),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildPostsList(),
                _buildNewsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioChip(String label, String ratio, IconData icon) {
    final isSelected = _selectedRatio == ratio;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1E90FF),
      backgroundColor: Colors.grey[200],
      onSelected: (_) {
        setState(() {
          _selectedRatio = ratio;
        });
      },
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1E90FF) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1E90FF) : Colors.grey[600],
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    // Instagram-style preview with proper aspect ratio
    final aspectRatio = _selectedRatio == 'square' ? 1.0 : 4.0 / 5.0;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_imageBase64 != null)
                Image.network(
                  _imageBase64!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _imageBase64 = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin will share posts soon!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildInstagramPost(post);
      },
    );
  }

  Widget _buildInstagramPost(Post post) {
    bool hasImage = post.image != null && post.image!.isNotEmpty;
    String? imageUrl = hasImage ? post.image : null;
    bool isLiked = _likedPosts[post.id] ?? false;
    int likeCount = _likeCounts[post.id] ?? 0;

    // Instagram aspect ratio from backend or default to portrait
    final ratio = post.imageRatio ?? 'portrait';
    final aspectRatio = ratio == 'square' ? 1.0 : 4.0 / 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: post.isOfficial ? Colors.green : const Color(0xFF1E90FF),
                  radius: 20,
                  child: Text(
                    post.addedBy.isNotEmpty ? post.addedBy[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _formatDate(post.addedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Content text
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 8),
          
          // Instagram-style Image with MAX HEIGHT LIMIT
          if (hasImage && imageUrl != null)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 500,  // <-- ইমেজ সর্বোচ্চ 500px হবে
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Image unavailable',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[700],
                    size: 28,
                  ),
                  onPressed: () {
                    if (post.id != null) {
                      _toggleLike(post.id!);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  likeCount > 0 ? '$likeCount' : '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDateDetailed(post.addedAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_news.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No news updates yet.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final news = _news[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF1E90FF),
                      child: Icon(
                        Icons.newspaper,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${news.source} • ${_formatDate(news.addedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  news.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (news.url != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      'Read More →',
                      style: TextStyle(
                        color: Color(0xFF1E90FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 30) {
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      } else if (difference.inDays > 7) {
        return '${difference.inDays}d ago';
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

  String _formatDateDetailed(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day} ${_getMonth(parsed.month)} ${parsed.year} at ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}