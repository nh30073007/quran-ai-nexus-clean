import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/models/news.dart';
import 'package:quran_ai_nexus/widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<News> _news = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Islamic News',
    'Community Updates',
    'Scholars',
    'Events',
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    try {
      final newsData = await ApiService.getNews();
      setState(() {
        _news = newsData.map((json) => News.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isSelected
                        ? const Color(0xFF1E90FF)
                        : Colors.transparent,
                    selectedColor: const Color(0xFF1E90FF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // News List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _news.isEmpty
                    ? const Center(
                        child: Text('No news available at the moment.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _news.length,
                        itemBuilder: (context, index) {
                          final news = _news[index];
                          return NewsCard(news: news);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}