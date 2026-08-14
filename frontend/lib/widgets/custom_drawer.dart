import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_ai_nexus/providers/auth_provider.dart';
import 'package:quran_ai_nexus/providers/theme_provider.dart';
import 'package:quran_ai_nexus/providers/language_provider.dart';
import 'package:quran_ai_nexus/providers/navigation_provider.dart';
import 'package:quran_ai_nexus/screens/admin_panel_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E90FF), Color(0xFF87CEEB)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  '🕌 Quran AI Nexus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Divine Guidance Through AI',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Welcome, ${authProvider.user?.username ?? "Admin"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.search,
                  title: 'Ask Quran',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.chat,
                  title: 'Quran Chat',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.feed,
                  title: 'Community Feed',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.psychology,
                  title: 'Guidance',
                  index: 3,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Daily Verse',
                  index: 4,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.newspaper,
                  title: 'News',
                  index: 5,
                ),
                const Divider(),
                
                // Admin Panel
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF1E90FF)),
                  title: const Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E90FF),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPanelScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                
                // Theme Toggle
                ListTile(
                  leading: Icon(
                    themeProvider.isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: Text(
                    themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
                  ),
                  onTap: () {
                    themeProvider.toggleTheme();
                    Navigator.pop(context);
                  },
                ),
                
                // Language Toggle
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    languageProvider.currentLanguage == 'en'
                        ? 'Switch to বাংলা'
                        : 'Switch to English',
                  ),
                  onTap: () {
                    languageProvider.toggleLanguage();
                    Navigator.pop(context);
                  },
                ),
                
                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '© 2025 Quran AI Nexus',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        // Use provider to change tab
        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
        navProvider.changeTab(index);
      },
    );
  }
}