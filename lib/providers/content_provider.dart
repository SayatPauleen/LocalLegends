import 'package:flutter/foundation.dart';

import '../data/sample_content_repository.dart';
import '../models/app_models.dart';

/// State shared by several tabs: supported places (Support = favorite)
/// and story drafts (continue or discard). In memory for now; move to
/// users/{uid}/supported and users/{uid}/drafts in Firestore later.
class ContentProvider extends ChangeNotifier {
  ContentProvider([this._repo = const SampleContentRepository()])
      : _drafts = List.of(_repo.drafts());

  final SampleContentRepository _repo;
  final Set<String> _supported = {'p1', 'p4'};
  final List<StoryDraft> _drafts;

  List<Place> get places => _repo.places();
  List<Mission> get missions => _repo.missions();
  List<MissionBadge> get badges => _repo.badges();
  List<TransformationCollection> get collections => _repo.collections();
  List<StoryDraft> get drafts => List.unmodifiable(_drafts);

  int get points => _repo.points();
  int get level => points ~/ 100 + 1;

  bool isSupported(String placeId) => _supported.contains(placeId);
  int get supportedCount => _supported.length;
  List<Place> get supportedPlaces =>
      places.where((p) => _supported.contains(p.id)).toList();

  void toggleSupport(String placeId) {
    if (!_supported.remove(placeId)) _supported.add(placeId);
    notifyListeners();
  }

  void discardDraft(String draftId) {
    _drafts.removeWhere((d) => d.id == draftId);
    notifyListeners();
  }
}
