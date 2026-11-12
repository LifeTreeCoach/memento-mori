import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/enhanced_friends_screen.dart';
import 'package:memento_mori_life_in_weeks/home_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_launches.dart';
import 'package:memento_mori_life_in_weeks/settings_screen.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_launcher.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';

/// Top-level tabs: Life, Compass, People, Settings. Tabs keep their state; hidden
/// tabs have their tickers disabled. A home-screen widget tap always shows
/// the Life tab, a weekly reflection notification tap or an in-app
/// [CompassLaunchRequests] request the Compass tab, and a birthday
/// notification tap the People tab with that friend's detail on top. A
/// Compass reminder tap shows the weekly moment first when it is due, and
/// opening or resuming the app catches a missed one up.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.now,
    this.widgetLaunches = const PlatformWidgetLaunches(),
    this.notificationLaunches = const PlatformNotificationLaunches(),
    this.weekMoments = const WeekMomentLauncher(),
    this.clock,
  });

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Source of home-screen widget taps.
  final WidgetLaunches widgetLaunches;

  /// Source of notification taps that open the Compass or People tab.
  final NotificationLaunches notificationLaunches;

  /// Shows the weekly moment on a reminder tap and as a catch-up.
  final WeekMomentLauncher weekMoments;

  /// Clock of the weekly moment (tests); defaults to [now], else the clock.
  final DateTime Function()? clock;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _lifeTab = 0;
  static const int _compassTab = 1;
  static const int _peopleTab = 2;
  static const int _settingsTab = 3;

  int _index = _lifeTab;
  StreamSubscription<void>? _widgetLaunchSubscription;
  StreamSubscription<void>? _notificationLaunchSubscription;
  StreamSubscription<void>? _compassRequestSubscription;
  late final AppLifecycleListener _lifecycle;
  Timer? _catchUpTimer;

  /// Whether the weekly moment is being decided on or shown.
  bool _momentOpen = false;

  /// A Compass tap arrived while the moment was open.
  bool _compassAfterMoment = false;

  /// Friend ids whose detail the People tab should open.
  final StreamController<String> _friendRequests =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _widgetLaunchSubscription = widget.widgetLaunches.listen(_showLife);
    _notificationLaunchSubscription =
        widget.notificationLaunches.listen(_onNotificationLaunch);
    _compassRequestSubscription = CompassLaunchRequests.listen(_showCompass);
    _lifecycle = AppLifecycleListener(onResume: _scheduleCatchUp);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleCatchUp());
  }

  @override
  void dispose() {
    _widgetLaunchSubscription?.cancel();
    _notificationLaunchSubscription?.cancel();
    _compassRequestSubscription?.cancel();
    _lifecycle.dispose();
    _catchUpTimer?.cancel();
    _friendRequests.close();
    super.dispose();
  }

  void _showLife() => _showTab(_lifeTab);

  void _showCompass() => _showTab(_compassTab);

  void _onNotificationLaunch(NotificationLaunch launch) => switch (launch) {
        CompassLaunch(:final reminderDay) => _onCompassReminder(reminderDay),
        PeopleLaunch(:final friendId) => _showPeople(friendId),
      };

  DateTime _momentNow() =>
      widget.clock?.call() ?? widget.now ?? DateTime.now();

  /// A Compass reminder tap: the weekly moment first (if due), then the
  /// Compass tab unless the moment was closed. The tab switches only after
  /// the moment popped, so the Compass setup and tour never open under it.
  Future<void> _onCompassReminder(DateTime? reminderDay) async {
    if (!mounted) return;
    if (_momentOpen) {
      _compassAfterMoment = true;
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    final result = await _runMoment((context) => widget.weekMoments
        .forReminder(context, reminderDay: reminderDay, now: _momentNow()));
    if (_takeCompassAfterMoment() || result != WeekMomentResult.closed) {
      _showCompass();
    }
  }

  /// Looks for a missed moment once the app had [WeekMomentLauncher.settle]
  /// to start or resume (a reminder tap arriving meanwhile wins).
  void _scheduleCatchUp() {
    _catchUpTimer?.cancel();
    _catchUpTimer = Timer(WeekMomentLauncher.settle, _catchUp);
  }

  /// The catch-up, never over another route (sheet, dialog, setup, tour).
  Future<void> _catchUp() async {
    if (!mounted || _momentOpen) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final result = await _runMoment((context) =>
        widget.weekMoments.catchUpIfDue(context, now: _momentNow()));
    if (_takeCompassAfterMoment() || result == WeekMomentResult.continued) {
      _showCompass();
    }
  }

  /// Runs [launch] with [_momentOpen] set for its whole duration.
  Future<WeekMomentResult> _runMoment(
      Future<WeekMomentResult> Function(BuildContext context) launch) async {
    _momentOpen = true;
    try {
      return await launch(context);
    } finally {
      _momentOpen = false;
    }
  }

  bool _takeCompassAfterMoment() {
    final wanted = _compassAfterMoment;
    _compassAfterMoment = false;
    return wanted;
  }

  /// Shows the People tab and asks it to open [friendId]'s detail, if any.
  void _showPeople(String? friendId) {
    _showTab(_peopleTab);
    if (mounted && friendId != null) _friendRequests.add(friendId);
  }

  /// Closes anything pushed above the shell (detail screens, sheets,
  /// dialogs) and selects the tab at [index].
  void _showTab(int index) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (_index != index) setState(() => _index = index);
  }

  void _select(int index) {
    if (index == _index) return;
    Haptics.selection();
    // Rebuilding the pages lets each tab re-read settings changed elsewhere.
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenSettings: () => _select(_settingsTab),
        onOpenCompass: () => _select(_compassTab),
        now: widget.now,
      ),
      CompassScreen(now: widget.now, autoOpenSetup: true),
      EnhancedFriendsScreen(
        now: widget.now,
        openFriendRequests: _friendRequests.stream,
      ),
      // Not const, so Settings re-reads values changed on other tabs.
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (int i = 0; i < pages.length; i++)
            TickerMode(enabled: i == _index, child: pages[i]),
        ],
      ),
      bottomNavigationBar: _navigationBar(context),
    );
  }

  Widget _navigationBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.hourglass_empty_rounded),
          selectedIcon: const Icon(Icons.hourglass_bottom_rounded),
          label: l10n.translate('nav_life'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore_rounded),
          label: l10n.translate('nav_compass'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded),
          selectedIcon: const Icon(Icons.people_rounded),
          label: l10n.translate('nav_people'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n.translate('settings'),
        ),
      ],
    );
  }
}
