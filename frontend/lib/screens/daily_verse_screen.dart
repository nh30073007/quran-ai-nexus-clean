import 'package:flutter/material.dart';
import 'package:quran_ai_nexus/services/api_service.dart';
import 'package:quran_ai_nexus/widgets/verse_card.dart';
import 'package:quran_ai_nexus/widgets/tafsir_section.dart';
import 'package:quran_ai_nexus/widgets/sufi_insight.dart';
import 'package:audioplayers/audioplayers.dart';

class DailyVerseScreen extends StatefulWidget {
  const DailyVerseScreen({super.key});

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen> {
  Map<String, dynamic>? _dailyVerse;
  bool _isLoading = true;
  bool _showTafsir = false;
  bool _showSufi = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadDailyVerse();
  }

  Future<void> _loadDailyVerse() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getDailyGuidance();
      setState(() {
        _dailyVerse = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playAudio(String text) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
        return;
      }
      
      // Note: You would need a TTS service endpoint
      // For now, we'll just show a message
      setState(() => _isPlaying = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isPlaying = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio playback feature coming soon'),
        ),
      );
    } catch (e) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Verse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDailyVerse,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dailyVerse == null
              ? const Center(child: Text('No verse available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E90FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF1E90FF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dailyVerse!['date'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E90FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Verse Card
                      VerseCard(
                        verse: _dailyVerse!['verse'] ?? {},
                      ),
                      const SizedBox(height: 16),

                      // Audio Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = _dailyVerse!['verse']?['text_arabic'] ?? '';
                            _playAudio(text);
                          },
                          icon: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            _isPlaying ? 'Stop Recitation' : 'Listen to Verse',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tafsir Section
                      TafsirSection(
                        verse: _dailyVerse!['verse'] ?? {},
                        isExpanded: _showTafsir,
                        onToggle: () {
                          setState(() {
                            _showTafsir = !_showTafsir;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sufi Insights
                      SufiInsight(
                        verse: _dailyVerse!['verse'] ?? {},
                        isExpanded: _showSufi,
                        onToggle: () {
                          setState(() {
                            _showSufi = !_showSufi;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Reflection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Reflection',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _dailyVerse!['reflection'] ?? '',
                              style: const TextStyle(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dua
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.handshake,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Dua',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _dailyVerse!['dua'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Share Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share this Verse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E90FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}