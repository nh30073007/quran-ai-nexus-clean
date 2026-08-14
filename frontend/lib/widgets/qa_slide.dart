import 'package:flutter/material.dart';

class QASlide extends StatefulWidget {
  final List<Map<String, String>> qaData;
  final String category;

  const QASlide({
    super.key,
    required this.qaData,
    required this.category,
  });

  @override
  State<QASlide> createState() => _QASlideState();
}

class _QASlideState extends State<QASlide> {
  int _currentIndex = 0;

  void _nextSlide() {
    if (_currentIndex < widget.qaData.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E90FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E90FF),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // QA Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(_currentIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '❓ Question',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.qaData[_currentIndex]['q'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Answer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Answer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.qaData[_currentIndex]['a'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousSlide : null,
                  icon: const Icon(Icons.chevron_left),
                  color: _currentIndex > 0 ? const Color(0xFF1E90FF) : Colors.grey,
                ),
                Text(
                  '${_currentIndex + 1} / ${widget.qaData.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: _currentIndex < widget.qaData.length - 1 ? _nextSlide : null,
                  icon: const Icon(Icons.chevron_right),
                  color: _currentIndex < widget.qaData.length - 1
                      ? const Color(0xFF1E90FF)
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}