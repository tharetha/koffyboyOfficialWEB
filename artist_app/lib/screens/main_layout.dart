import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import 'dashboard_screen.dart';
import 'store_manager_screen.dart';
import 'music_manager_screen.dart';
import 'profile_manager_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StoreManagerScreen(),
    MusicManagerScreen(),
    ProfileManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Needed for floating nav bar to overlay the body
      appBar: AppBar(
        title: const Row(
          children: [
            Text('KOFFYBOY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            Text('official', style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFFFF9900))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
