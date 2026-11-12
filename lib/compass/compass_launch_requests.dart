import 'dart:async';

import 'package:flutter/foundation.dart';

/// In-app requests to show the Compass tab from screens pushed above the
/// shell (e.g. "Open" on the "Plan time together" snackbar). The shell
/// listens, closes the pushed screens and selects the Compass tab.
class CompassLaunchRequests {
  CompassLaunchRequests._();

  static StreamController<void> _requests = StreamController<void>.broadcast();

  /// Asks the shell to show the Compass tab.
  static void request() => _requests.add(null);

  /// Calls [onRequest] for every request. Cancel to stop listening.
  static StreamSubscription<void> listen(VoidCallback onRequest) =>
      _requests.stream.listen((_) => onRequest());

  @visibleForTesting
  static void resetForTesting() {
    _requests.close();
    _requests = StreamController<void>.broadcast();
  }
}
