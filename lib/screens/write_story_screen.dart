import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/reward_dialog.dart';

/// What the editor returns to the screen that opened it.
enum _StoryOutcome { posted, savedDraft, discarded }

class _EditorResult {
  const _EditorResult(this.outcome, [this.rewards = const []]);
  final _StoryOutcome outcome;
  final List<MissionReward> rewards;
}

/// Write a Story: place, story, "Who did you meet?", "What makes it special?",
/// with Post, Save Draft and Discard (with a confirmation).
class WriteStoryScreen extends StatefulWidget {
  const WriteStoryScreen({super.key, this.place, this.draft});

  final Place? place;
  final StoryDraft? draft;

  /// Opens the editor and, after posting, shows the points earned on the
  /// screen that opened it.
  static Future<void> open(BuildContext context, {Place? place, StoryDraft? draft}) async {
    final result = await Navigator.of(context).push<_EditorResult>(
      MaterialPageRoute(builder: (_) => WriteStoryScreen(place: place, draft: draft)),
    );
    if (result == null || !context.mounted) return;
    switch (result.outcome) {
      case _StoryOutcome.posted:
        showMessage(context, 'Story posted. Thanks for sharing!');
        await showRewards(context, result.rewards);
      case _StoryOutcome.savedDraft:
        showMessage(context, 'Draft saved. Find it in Profile > Drafts.');
      case _StoryOutcome.discarded:
        showMessage(context, 'Story discarded.');
    }
  }

  @override
  State<WriteStoryScreen> createState() => _WriteStoryScreenState();
}

class _WriteStoryScreenState extends State<WriteStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _story;
  late final TextEditingController _met;
  late final TextEditingController _special;
  Place? _place;
  String? _draftId;
  bool _busy = false;
  bool _placeMissing = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _draftId = d?.id;
    _story = TextEditingController(text: d?.text ?? '');
    _met = TextEditingController(text: d?.whoTheyMet ?? '');
    _special = TextEditingController(text: d?.whatMakesItSpecial ?? '');
    final content = context.read<ContentProvider>();
    _place = widget.place ?? content.placeById(d?.placeId);
    if (_place == null && d != null) {
      for (final p in content.places) {
        if (p.name == d.placeName) _place = p;
      }
    }
  }

  @override
  void dispose() {
    _story.dispose();
    _met.dispose();
    _special.dispose();
    super.dispose();
  }

  bool get _hasText =>
      _story.text.trim().isNotEmpty ||
      _met.text.trim().isNotEmpty ||
      _special.text.trim().isNotEmpty;

  Future<void> _pickPlace() async {
    final places = context.read<ContentProvider>().places;
    final picked = await showModalBottomSheet<Place>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Which place is your story about?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            for (final p in places)
              ListTile(
                leading: Icon(p.category.icon, color: AppColors.terracotta),
                title: Text(p.name),
                subtitle: Text('${p.category.label} · ${p.distanceKm.toStringAsFixed(1)} km'),
                trailing: p.id == _place?.id ? const Icon(Icons.check, color: AppColors.teal) : null,
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _place = picked;
        _placeMissing = false;
      });
    }
  }

  Future<void> _post() async {
    final place = _place;
    setState(() => _placeMissing = place == null);
    final valid = _formKey.currentState!.validate();
    if (place == null || !valid) return;

    setState(() => _busy = true);
    try {
      final rewards = await context.read<ContentProvider>().publishStory(
            place: place,
            text: _story.text,
            whoTheyMet: _met.text,
            whatMakesItSpecial: _special.text,
            fromDraftId: _draftId,
          );
      if (mounted) Navigator.of(context).pop(_EditorResult(_StoryOutcome.posted, rewards));
    } catch (e) {
      debugPrint('Could not post story: $e');
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, 'Could not post your story. Check your connection and try again.');
      }
    }
  }

  Future<void> _saveDraft() async {
    final place = _place;
    if (place == null) {
      setState(() => _placeMissing = true);
      return;
    }
    if (!_hasText) {
      showMessage(context, 'Write something first, then save it as a draft.');
      return;
    }
    setState(() => _busy = true);
    await context.read<ContentProvider>().saveDraft(
          draftId: _draftId,
          place: place,
          text: _story.text,
          whoTheyMet: _met.text,
          whatMakesItSpecial: _special.text,
        );
    if (mounted) Navigator.of(context).pop(const _EditorResult(_StoryOutcome.savedDraft));
  }

  Future<void> _discard() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this story?'),
        content: Text(_draftId == null
            ? 'What you wrote will be lost.'
            : 'The saved draft will be deleted too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep writing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final id = _draftId;
    if (id != null) await context.read<ContentProvider>().discardDraft(id);
    if (mounted) Navigator.of(context).pop(const _EditorResult(_StoryOutcome.discarded));
  }

  /// Back button with unsaved text: same choice as Discard.
  Future<void> _onBack() async {
    if (_busy) return;
    if (!_hasText) {
      Navigator.of(context).pop();
      return;
    }
    await _discard();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_draftId == null ? 'Write a Story' : 'Edit draft')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text('Place', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 6),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _placeMissing ? Colors.red : AppColors.border),
                ),
                child: ListTile(
                  onTap: _busy ? null : _pickPlace,
                  leading: Icon(_place?.category.icon ?? Icons.place_outlined,
                      color: AppColors.terracotta),
                  title: Text(_place?.name ?? 'Choose a place'),
                  subtitle: _place == null ? null : Text(_place!.category.label),
                  trailing: const Icon(Icons.expand_more),
                ),
              ),
              if (_placeMissing)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 12),
                  child: Text('Choose the place your story is about.',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _story,
                enabled: !_busy,
                minLines: 5,
                maxLines: 10,
                maxLength: ContentProvider.maxStoryLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your story',
                  hintText: 'What happened? What did it feel like to be there?',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Tell us a little about your visit.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _met,
                enabled: !_busy,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Who did you meet? (optional)',
                  hintText: 'The owner, a vendor, a regular...',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _special,
                enabled: !_busy,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What makes it special? (optional)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _post,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.terracotta,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _saveDraft,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                      child: const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: _busy ? null : _discard,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
