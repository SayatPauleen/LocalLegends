import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_dashboard_repository.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

/// The logged-in app: bottom navigation with the five tabs from the mockup.
/// Only Discover (the dashboard) is built so far; the others are stubs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = HomeTabs.discover;
  final _data = SampleDashboardRepository().load();

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.user?.displayName;
    final emailName = auth.user?.email?.split('@').first;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim().split(' ').first
        : (emailName ?? 'Explorer');

    final pages = <Widget>[
      DashboardScreen(
        userName: userName,
        data: _data,
        onSignOut: auth.signOut,
        onOpenTab: _openTab,
      ),
      const _ComingSoonTab(title: 'Map', featureId: 'F-04', icon: Icons.map_outlined),
      const _ComingSoonTab(title: 'Mystery Missions', featureId: 'F-07', icon: Icons.flag_outlined),
      const _ComingSoonTab(title: 'Post a story', featureId: 'F-03', icon: Icons.edit_note),
      const _ComingSoonTab(title: 'Support history', featureId: 'F-10', icon: Icons.volunteer_activism_outlined),
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
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.terracotta),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.terracotta),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: AppColors.terracotta),
            label: 'Missions',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: AppColors.terracotta),
            label: 'Post story',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism, color: AppColors.terracotta),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.title, required this.featureId, required this.icon});

  final String title;
  final String featureId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.terracotta),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Coming soon ($featureId)',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
