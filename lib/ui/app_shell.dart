import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/wishlist/wishlist_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      WishlistScreen(),
      NotesScreen(),
      FeedScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.auto_stories), label: 'Feed'),
        ],
      ),
    );
  }
}

