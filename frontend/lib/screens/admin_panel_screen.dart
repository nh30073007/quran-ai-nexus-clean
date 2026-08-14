import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_ai_nexus/providers/auth_provider.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/models/post.dart';
import 'package:quran_ai_nexus/models/news.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _newsTitleController = TextEditingController();
  final TextEditingController _newsDescController = TextEditingController();
  final TextEditingController _newsSourceController = TextEditingController();
  final TextEditingController _newsUrlController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  
  List<Post> _posts = [];
  List<News> _news = [];
  List<Map<String, dynamic>> _statusList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  File? _selectedImage;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _newsTitleController.dispose();
    _newsDescController.dispose();
    _newsSourceController.dispose();
    _newsUrlController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final postsData = await ApiService.getPosts();
      final newsData = await ApiService.getNews();
      final statusData = await ApiService.getStatus();
      
      setState(() {
        _posts = postsData.map((json) => Post.fromJson(json)).toList();
        _news = newsData.map((json) => News.fromJson(json)).toList();
        _statusList = statusData.map((json) => json as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  String _getMimeType(String path) {
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 2000,     // Max size for quality
    maxHeight: 2000,
    imageQuality: 100,  // No compression (best quality)
  );
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    print('📸 Original image size: ${bytes.length / 1024} KB');
    
    // Only compress if REALLY large (> 2MB)
    var finalBytes = bytes;
    if (bytes.length > 2 * 1024 * 1024) { // > 2MB
      final compressedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 95,
      );
      if (compressedFile != null) {
        finalBytes = await compressedFile.readAsBytes();
        print('📸 Compressed size: ${finalBytes.length / 1024} KB');
      }
    }
    
    final base64String = base64Encode(finalBytes);
    final mimeType = _getMimeType(pickedFile.path);
    
    setState(() {
      _selectedImage = File(pickedFile.path);
      _imageBase64 = 'data:$mimeType;base64,$base64String';
    });
    
    print('📸 Final image size: ${finalBytes.length / 1024} KB');
  }
}

  Future<void> _createPost() async {
    if (_postController.text.isEmpty && _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter post content or add image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.createPostWithMedia(
        text: _postController.text,
        isOfficial: true,
        imageData: _imageBase64,
      );
      
      if (result['message'] != null) {
        _postController.clear();
        setState(() {
          _selectedImage = null;
          _imageBase64 = null;
        });
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _createStatus() async {
    if (_statusController.text.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    try {
      await ApiService.createPost(text: _statusController.text, isOfficial: false);
      _statusController.clear();
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: const Color(0xFF1E90FF),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You need to login as admin first', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: const Color(0xFF1E90FF),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Admin Only', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You do not have admin privileges', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  authProvider.logout();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout & Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1E90FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📝 Post', icon: Icon(Icons.post_add)),
            Tab(text: '📰 News', icon: Icon(Icons.newspaper)),
            Tab(text: '📊 Status', icon: Icon(Icons.update)),
            Tab(text: '📋 Manage', icon: Icon(Icons.list)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreatePostTab(),
          _buildAddNewsTab(),
          _buildStatusTab(),
          _buildManageContentTab(),
        ],
      ),
    );
  }

  Widget _buildCreatePostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Post',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _postController,
            decoration: const InputDecoration(
              labelText: 'Post Content',
              hintText: 'Write your Islamic reflection here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedImage != null)
                Expanded(
                  child: Text(
                    '✅ Image selected',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageBase64!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E90FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish Post', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add News Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newsTitleController,
            decoration: const InputDecoration(
              labelText: 'News Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newsDescController,
            decoration: const InputDecoration(
              labelText: 'News Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newsSourceController,
            decoration: const InputDecoration(
              labelText: 'Source',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newsUrlController,
            decoration: const InputDecoration(
              labelText: 'URL (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('News feature coming soon!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E90FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add News', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _statusController,
            decoration: const InputDecoration(
              labelText: 'Status Update',
              hintText: 'Share an update with the community...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E90FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Status', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Status Updates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_statusList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No status updates yet'),
              ),
            )
          else
            ..._statusList.map((status) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(status['text'] ?? ''),
                subtitle: Text('by ${status['added_by'] ?? 'admin'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStatus(status['id']),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildManageContentTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '📝 Posts'),
              Tab(text: '📰 News'),
            ],
            labelColor: Color(0xFF1E90FF),
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
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

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return const Center(child: Text('No posts found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: post.isOfficial 
                ? const Icon(Icons.verified, color: Colors.green)
                : null,
            title: Text(
              post.text.length > 50 ? '${post.text.substring(0, 50)}...' : post.text,
            ),
            subtitle: Text('by ${post.addedBy} • ${post.addedAt}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete('post', post.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsList() {
    if (_news.isEmpty) {
      return const Center(child: Text('No news found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final news = _news[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(news.title),
            subtitle: Text('${news.source} • ${news.addedAt}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete('news', news.id),
            ),
          ),
        );
      },
    );
  }

  void _deleteStatus(int? id) async {
    if (id == null) return;
    setState(() {
      _statusList.removeWhere((s) => s['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status deleted!')),
    );
  }

  Future<void> _confirmDelete(String type, int? id) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type deleted successfully!')),
      );
      await _loadData();
    }
  }
}