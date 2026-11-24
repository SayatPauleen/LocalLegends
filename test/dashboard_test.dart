import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/data/activity_store.dart';
import 'package:local_legends/data/sample_dashboard_repository.dart';
import 'package:local_legends/providers/content_provider.dart';
import 'package:local_legends/providers/tab_navigator.dart';
import 'package:local_legends/screens/dashboard_screen.dart';
import 'package:local_legends/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  late ContentProvider content;
  late TabNavigator nav;

  Future<void> pumpDashboard(WidgetTester tester) async {
    // Tall test screen so the whole feed is built.
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    content = ContentProvider(store: MemoryActivityStore());
    nav = TabNavigator();
    content.attachUser('u1', 'Pauleen');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: content),
          ChangeNotifierProvider.value(value: nav),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: DashboardScreen(userName: 'Pauleen', onSignOut: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('greets the user and shows points and stats', (tester) async {
    await pumpDashboard(tester);
    expect(find.textContaining('Pauleen'), findsOneWidget);
    expect(find.text('0 pts'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget); // weekly missions
    expect(find.text('Places supported'), findsOneWidget);
  });

  testWidgets('category chip filters the story feed', (tester) async {
    await pumpDashboard(tester);
    // Story text only appears in the feed, not in the gem cards.
    expect(find.textContaining('Rainy afternoon'), findsOneWidget);
    expect(find.textContaining('Local art students'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cultural'));
    await tester.pump();

    expect(find.textContaining('Rainy afternoon'), findsNothing);
    expect(find.textContaining('Local art students'), findsOneWidget);
  });

  testWidgets('Different one changes the clue, Accept starts the mission', (tester) async {
    await pumpDashboard(tester);
    final first = SampleDashboardRepository().load().missionClues.first.clue;
    expect(find.text(first), findsOneWidget);

    await tester.tap(find.text('Different one'));
    await tester.pumpAndSettle();
    expect(find.text(first), findsNothing);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('I found it'), findsOneWidget);
    expect(content.mysteryAccepted, isTrue);
  });

  testWidgets('points card opens the Missions tab', (tester) async {
    await pumpDashboard(tester);
    await tester.tap(find.text('0 pts'));
    expect(nav.index, HomeTabs.missions);
  });

  testWidgets('search sends the text to Explore', (tester) async {
    await pumpDashboard(tester);
    await tester.enterText(find.byType(TextField).first, 'lomi');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(nav.index, HomeTabs.explore);
    expect(nav.takeExploreSearch()?.query, 'lomi');
  });

  testWidgets('supporting a gem updates the stat and shows points', (tester) async {
    await pumpDashboard(tester);
    await tester.tap(find.byTooltip('Support').first);
    await tester.pumpAndSettle();

    expect(find.text('Mission completed!'), findsOneWidget);
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(content.supportedCount, 1);
    expect(find.text('20 pts'), findsOneWidget);
  });
}
