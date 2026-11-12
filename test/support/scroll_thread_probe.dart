import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// A phone-sized viewport (logical pixels) where the tabs overflow.
const Size phoneViewport = Size(393, 851);

/// Target opacity of the [ScrollThread] (1 = shown, 0 = hidden).
double scrollThreadOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byKey(ScrollThread.threadKey))
    .opacity;
