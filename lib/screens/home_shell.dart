import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_dashboard_repository.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'collections_screen.dart';
import 'dashboard_screen.dart';
import 'explore_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';

/// The logged-in app: bottom navigation with the five revision-2 tabs:
/// Home (Dashboard), Explore, Missions, Collections, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = HomeTabs.home;
  final _data = SampleDashboardRepository().load();

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.user?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim().split(' ').first
        : (auth.username ?? 'Explorer');

    final pages = <Widget>[
      DashboardScreen(
        userName: userName,
        data: _data,
        onSignOut: auth.signOut,
        onOpenTab: _openTab,
      ),
      const ExploreScreen(),
      const MissionsScreen(),
      const CollectionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.terracotta.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.terracotta),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.terracotta),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: AppColors.terracotta),
            label: 'Missions',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: AppColors.terracotta),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.terracotta),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
