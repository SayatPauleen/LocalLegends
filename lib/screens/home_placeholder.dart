import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Temporary landing screen proving login works.
/// Replace with the Discover/Map tabs once those features are built.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.displayName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalLegends'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(onPressed: auth.signOut, child: const Text('Log out')),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            name == null || name.isEmpty
                ? 'You are logged in.'
                : 'Welcome, $name. You are logged in.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
