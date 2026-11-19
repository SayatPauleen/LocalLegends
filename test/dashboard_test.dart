import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/data/sample_dashboard_repository.dart';
import 'package:local_legends/screens/dashboard_screen.dart';
import 'package:local_legends/theme/app_theme.dart';

void main() {
  Future<void> pumpDashboard(WidgetTester tester, {ValueChanged<int>? onOpenTab}) async {
    // Tall test screen so the whole feed is built.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: DashboardScreen(
            userName: 'Pauleen',
            data: SampleDashboardRepository().load(),
            onSignOut: () {},
            onOpenTab: onOpenTab ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('greets the user and shows stats', (tester) async {
    await pumpDashboard(tester);
    expect(find.textContaining('Pauleen'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Places supported'), findsOneWidget);
  });

  testWidgets('category chip filters the story feed', (tester) async {
    await pumpDashboard(tester);
    expect(find.text('Old Town Heritage Mural'), findsOneWidget);
    expect(find.text("Aling Rosa's Lomi House"), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cultural'));
    await tester.pump();

    expect(find.text('Old Town Heritage Mural'), findsOneWidget);
    expect(find.text("Aling Rosa's Lomi House"), findsNothing);
  });

  testWidgets('Different one changes the mission clue', (tester) async {
    await pumpDashboard(tester);
    final first = SampleDashboardRepository().load().missionClues.first.clue;
    expect(find.text(first), findsOneWidget);

    await tester.tap(find.text('Different one'));
    await tester.pump();

    expect(find.text(first), findsNothing);
  });

  testWidgets('Accept opens the Missions tab', (tester) async {
    int? opened;
    await pumpDashboard(tester, onOpenTab: (i) => opened = i);
    await tester.tap(find.text('Accept'));
    expect(opened, HomeTabs.missions);
  });
}
