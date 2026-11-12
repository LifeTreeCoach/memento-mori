import 'package:flutter/material.dart';

/// How long a snackbar with an action ("Undo", "Open") stays on screen:
/// twice Flutter's 4 s default, long enough to read it and reach the button.
const Duration actionSnackBarDuration = Duration(seconds: 8);

/// Undo offers for changes to many entries at once (e.g. a birthday import):
/// more is at stake, so they stay a little longer.
const Duration bulkActionSnackBarDuration = Duration(seconds: 12);

/// The one snackbar used for every "Undo"/"Open" offer.
///
/// `persist: false` is required: a [SnackBar] with an action otherwise
/// persists until dismissed and ignores [duration].
SnackBar actionSnackBar({
  required String text,
  required SnackBarAction action,
  Duration duration = actionSnackBarDuration,
}) =>
    SnackBar(
      content: Text(text),
      action: action,
      persist: false,
      duration: duration,
    );

/// Replaces the current snackbar of [messenger] with an [actionSnackBar];
/// its controller tells when the offer is gone (`closed`).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showActionSnackBar(
  ScaffoldMessengerState messenger, {
  required String text,
  required SnackBarAction action,
  Duration duration = actionSnackBarDuration,
}) {
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    actionSnackBar(text: text, action: action, duration: duration),
  );
}
