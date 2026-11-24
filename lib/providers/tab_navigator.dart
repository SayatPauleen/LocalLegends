import 'package:flutter/foundation.dart';

import '../models/dashboard_models.dart';

/// Tab indexes in HomeShell.
/// Revision 2 tabs: Home, Explore, Missions, Collections, Profile.
class HomeTabs {
  static const home = 0;
  static const explore = 1;
  static const missions = 2;
  static const collections = 3;
  static const profile = 4;
}

/// Lets any screen switch the bottom tab, and lets Home hand a search
/// (text and category) to Explore.
class TabNavigator extends ChangeNotifier {
  int _index = HomeTabs.home;
  int get index => _index;

  String? _pendingQuery;
  GemCategory? _pendingCategory;
  bool _hasPendingSearch = false;

  void open(int tab) {
    if (tab == _index) return;
    _index = tab;
    notifyListeners();
  }

  /// Opens Explore with this search already filled in.
  void openExplore({String query = '', GemCategory? category}) {
    _pendingQuery = query;
    _pendingCategory = category;
    _hasPendingSearch = true;
    _index = HomeTabs.explore;
    notifyListeners();
  }

  /// Explore calls this to pick up a search sent from Home (once).
  ({String query, GemCategory? category})? takeExploreSearch() {
    if (!_hasPendingSearch) return null;
    _hasPendingSearch = false;
    return (query: _pendingQuery ?? '', category: _pendingCategory);
  }

  /// Back to Home after logging out.
  void reset() {
    _index = HomeTabs.home;
    _hasPendingSearch = false;
  }
}
