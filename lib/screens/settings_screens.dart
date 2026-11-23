import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Settings pages opened from Profile. The switches only change local
/// state for now; save them to users/{uid}/settings in Firestore later.

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _missionReminders = true;
  bool _nearbyAlerts = true;
  double _radiusKm = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily mission reminders'),
            subtitle: const Text('A nudge when new daily missions are ready'),
            value: _missionReminders,
            onChanged: (v) => setState(() => _missionReminders = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hidden gems nearby'),
            subtitle: const Text('Tell me when I’m close to a featured place'),
            value: _nearbyAlerts,
            onChanged: (v) => setState(() => _nearbyAlerts = v),
          ),
          const SizedBox(height: 12),
          Text('Discovery radius: ${_radiusKm.round()} km',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_radiusKm.round()} km',
            activeColor: AppColors.terracotta,
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _publicProfile = true;
  bool _showSupported = true;
  bool _shareLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public profile'),
            subtitle: const Text('Others can see your username and stories'),
            value: _publicProfile,
            onChanged: (v) => setState(() => _publicProfile = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show places I support'),
            value: _showSupported,
            onChanged: (v) => setState(() => _showSupported = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Attach location to my stories'),
            subtitle: const Text('Only the place, never your live location'),
            value: _shareLocation,
            onChanged: (v) => setState(() => _shareLocation = v),
          ),
        ],
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    ('1. Using LocalLegends', '[Write who can use the app and the basic rules here.]'),
    ('2. Your stories and photos', '[Write who owns posted content and how it can be used.]'),
    ('3. Community guidelines', '[Write what is not allowed: false reviews, harassment, spam.]'),
    ('4. Points, missions and badges', '[Write that points have no cash value, etc.]'),
    ('5. Changes to these terms', '[Write how users will be told about changes.]'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (title, body) in _sections) ...[
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
