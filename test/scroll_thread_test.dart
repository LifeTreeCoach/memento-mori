import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

const _rowHeight = 100.0;

Future<void> _pump(
  WidgetTester tester, {
  int rows = 40,
  bool enabled = true,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = const Size(393, 851);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.light),
    home: Scaffold(
      body: ScrollThread(
        enabled: enabled,
        bottomInset: bottomInset,
        child: CustomScrollView(slivers: [
          SliverList.builder(
            itemCount: rows,
            itemBuilder: (context, index) =>
                SizedBox(height: _rowHeight, child: Text('Row $index')),
          ),
        ]),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byKey(ScrollThread.threadKey))
    .opacity;

Rect _threadRect(WidgetTester tester) => tester.getRect(find.descendant(
      of: find.byKey(ScrollThread.threadKey),
      matching: find.byType(DecoratedBox),
    ));

void main() {
  testWidgets('hidden while a dialog covers the screen', (tester) async {
    await _pump(tester);
    expect(_opacity(tester), 1);
    final context = tester.element(find.text('Row 0'));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(_opacity(tester), 0);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('a sheet\'s own thread shows while the screen below hides',
      (tester) async {
    await _pump(tester, rows: 3);
    showModalBottomSheet<void>(
      context: tester.element(find.text('Row 0')),
      builder: (_) => ScrollThread(
        child: ListView(children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: _rowHeight, child: Text('Sheet $i')),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    final sheetThread = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byKey(ScrollThread.threadKey),
    );
    expect(tester.widget<AnimatedOpacity>(sheetThread).opacity, 1);
  });

  testWidgets('visible at rest on first open with overflowing content',
      (tester) async {
    await _pump(tester);
    expect(_opacity(tester), 1);
    final thread = _threadRect(tester);
    expect(thread.top, 0);
    expect(thread.width, ScrollThread.width);
    expect(thread.right, 393 - ScrollThread.rightInset);
    // 851 of 4000 content => ~181 of the 851 track.
    expect(thread.height, closeTo(851 * 851 / 4000, 0.5));
  });

  testWidgets('appears one frame after the first layout, without scrolling',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ScrollThread(
        child: ListView(children: [
          for (var i = 0; i < 40; i++) const SizedBox(height: _rowHeight),
        ]),
      ),
    ));
    // ScrollMetricsNotification is dispatched in a post-frame callback.
    expect(_opacity(tester), 0);
    await tester.pump();
    expect(_opacity(tester), 1);
  });

  testWidgets('fades out at the end and returns after scrolling up',
      (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 0);
    expect(_threadRect(tester).bottom, closeTo(851, 0.5));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('moves with the scroll position', (tester) async {
    await _pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(_threadRect(tester).top, greaterThan(0));
  });

  testWidgets('hidden when the content fits', (tester) async {
    await _pump(tester, rows: 5);
    expect(_opacity(tester), 0);
  });

  testWidgets('hidden when disabled', (tester) async {
    await _pump(tester, enabled: false);
    expect(_opacity(tester), 0);
  });

  testWidgets('bottomInset shortens the track', (tester) async {
    await _pump(tester, bottomInset: 100);
    expect(_threadRect(tester).height, closeTo(751 * 851 / 4000, 0.5));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(_threadRect(tester).bottom, closeTo(751, 0.5));
  });

  testWidgets('scroll notifications keep bubbling', (tester) async {
    var received = 0;
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: NotificationListener<ScrollUpdateNotification>(
        onNotification: (_) {
          received++;
          return false;
        },
        child: ScrollThread(
          child: ListView(children: [
            for (var i = 0; i < 40; i++) const SizedBox(height: _rowHeight),
          ]),
        ),
      ),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(received, greaterThan(0));
  });
}
