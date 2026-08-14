import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/services/api_service.dart';

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  String _selectedFeeling = 'lost';
  final Map<String, String> _feelings = {
    'lost': 'Feeling Lost',
    'empty': 'Spiritual Emptiness',
    'broken': 'Broken Heart',
    'alone': 'Feeling Alone',
    'purpose': 'Finding Purpose',
  };
  
  bool _isLoading = false;
  Map<String, dynamic>? _guidance;
  Map<String, dynamic>? _dailyGuidance;

  @override
  void initState() {
    super.initState();
    _loadDailyGuidance();
  }

  Future<void> _loadDailyGuidance() async {
    try {
      final result = await ApiService.getDailyGuidance();
      setState(() => _dailyGuidance = result);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _getGuidance() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getLifeGuidance(
        topic: 'life',
        feeling: _selectedFeeling,
        language: 'en',
      );
      setState(() {
        _guidance = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Guidance
          if (_dailyGuidance != null) ...[
            const Text(
              '📖 Daily Guidance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dailyGuidance!['verse']['reference'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E90FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dailyGuidance!['verse']['text_arabic'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dailyGuidance!['verse']['translation_en'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💭 Reflection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_dailyGuidance!['reflection'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🤲 Dua',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dailyGuidance!['dua'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Life Guidance
          const Text(
            '🧭 Life Guidance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedFeeling,
            decoration: const InputDecoration(
              labelText: 'How are you feeling?',
              border: OutlineInputBorder(),
            ),
            items: _feelings.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedFeeling = value!);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _getGuidance,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Guidance'),
            ),
          ),
          const SizedBox(height: 16),

          // Guidance Result
          if (_guidance != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📿 Reminder',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_guidance!['reminder'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📜 Hadith',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_guidance!['hadith'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Practical Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...(_guidance!['practical_steps'] as List? ?? [])
                              .map((step) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(step)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}