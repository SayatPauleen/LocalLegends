import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/place_tile.dart';
import '../widgets/story_card.dart';
import 'settings_screens.dart';
import 'story_detail_screen.dart';
import 'write_story_screen.dart';

/// Profile tab: who you are, your stories, drafts, supported places,
/// and Settings (Preferences, Privacy, Terms and Conditions, Log out).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final content = context.watch<ContentProvider>();
    final myStories = content.myStories;

    final name = auth.user?.displayName?.trim();
    final displayName = (name == null || name.isEmpty) ? 'Explorer' : name;
    final handle = auth.username == null ? '' : '@${auth.username}';

    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      Text(
                        '$handle · Level ${content.level}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => _comingSoon(context, 'Editing your profile'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(value: '${content.storiesSharedCount}', label: 'Stories'),
                const SizedBox(width: 10),
                _Stat(value: '${content.supportedCount}', label: 'Supported'),
                const SizedBox(width: 10),
                _Stat(value: '${content.points}', label: 'Points'),
              ],
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelColor: AppColors.terracotta,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.terracotta,
              dividerColor: AppColors.border,
              tabs: [Tab(text: 'Stories'), Tab(text: 'Drafts'), Tab(text: 'Supported')],
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final tabs = DefaultTabController.of(context);
              return AnimatedBuilder(
                animation: tabs,
                builder: (_, __) {
                  switch (tabs.index) {
                    case 1:
                      return _DraftsList(drafts: content.drafts);
                    case 2:
                      final places = content.supportedPlaces;
                      if (places.isEmpty) {
                        return const _Empty('Tap Support on a place in Explore to see it here.');
                      }
                      return Column(children: [
                        for (final p in places)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PlaceTile(place: p),
                          ),
                      ]);
                    default:
                      if (myStories.isEmpty) {
                        return Column(children: [
                          const _Empty('No stories yet. Share what makes a place special.'),
                          FilledButton.icon(
                            onPressed: () => WriteStoryScreen.open(context),
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Write a Story'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppColors.terracotta,
                            ),
                          ),
                        ]);
                      }
                      return Column(children: [
                        for (final s in myStories)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: StoryCard(
                              story: s,
                              onTap: () => StoryDetailScreen.open(context, s),
                            ),
                          ),
                      ]);
                  }
                },
              );
            }),
            const SizedBox(height: 20),
            const Text(
              'SETTINGS',
              style: TextStyle(fontSize: 12, letterSpacing: 0.8, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            _SettingsTile(
              icon: Icons.tune,
              label: 'Preferences',
              onTap: () => _open(context, const PreferencesScreen()),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              label: 'Privacy',
              onTap: () => _open(context, const PrivacyScreen()),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms and Conditions',
              onTap: () => _open(context, const TermsScreen()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: AppColors.terracotta),
              title: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.terracotta),
              ),
              // AuthGate shows the welcome screen again by itself.
              onTap: auth.signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Drafts can be continued or discarded (revision 2).
class _DraftsList extends StatelessWidget {
  const _DraftsList({required this.drafts});

  final List<StoryDraft> drafts;

  Future<void> _confirmDiscard(BuildContext context, StoryDraft draft) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this draft?'),
        content: Text('Your story about ${draft.placeName} will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      context.read<ContentProvider>().discardDraft(draft.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) return const _Empty('No drafts. Stories you save for later show up here.');
    return Column(
      children: [
        for (final d in drafts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(d.placeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Draft',
                          style: TextStyle(fontSize: 11, color: AppColors.terracotta)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(d.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink, height: 1.4)),
                Row(
                  children: [
                    Text(d.savedAgo,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => WriteStoryScreen.open(context, draft: d),
                      child: const Text('Continue'),
                    ),
                    TextButton(
                      onPressed: () => _confirmDiscard(context, d),
                      child: const Text('Discard', style: TextStyle(color: AppColors.muted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.ink),
          title: Text(label, style: const TextStyle(color: AppColors.ink)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
