import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_ai_nexus/screens/ask_quran_screen.dart';
import 'package:quran_ai_nexus/screens/chat_screen.dart';
import 'package:quran_ai_nexus/screens/feed_screen.dart';
import 'package:quran_ai_nexus/screens/guidance_screen.dart';
import 'package:quran_ai_nexus/screens/daily_verse_screen.dart';
import 'package:quran_ai_nexus/screens/news_screen.dart';
import 'package:quran_ai_nexus/widgets/custom_drawer.dart';
import 'package:quran_ai_nexus/providers/navigation_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        final List<Widget> _screens = [
          const AskQuranScreen(),
          const ChatScreen(),
          const FeedScreen(),
          const GuidanceScreen(),
          const DailyVerseScreen(),
          const NewsScreen(),
        ];

        final List<String> _titles = [
          'Ask Quran',
          'Quran Chat',
          'Community Feed',
          'Guidance',
          'Daily Verse',
          'News',
        ];

        return Scaffold(
          drawer: const CustomDrawer(),
          appBar: AppBar(
            title: Text(_titles[navProvider.selectedIndex]),
            backgroundColor: const Color(0xFF1E90FF),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh logic
                },
              ),
            ],
          ),
          body: _screens[navProvider.selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navProvider.selectedIndex,
            onTap: (index) {
              navProvider.changeTab(index);
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Ask',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feed),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology),
                label: 'Guidance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Daily',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.newspaper),
                label: 'News',
              ),
            ],
          ),
        );
      },
    );
  }
}