import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The three colours of the "Together" chart and its legend.
@immutable
class SharedTimeColors {
  const SharedTimeColors({
    required this.together,
    required this.ahead,
    required this.own,
  });

  /// Chart colours for [palette] on a card of [scheme]: [own] is the
  /// remaining colour pulled towards [ColorScheme.onSurfaceVariant], so it
  /// stays visible on the card in light and dark mode.
  factory SharedTimeColors.resolve(LifePalette palette, ColorScheme scheme) {
    return SharedTimeColors(
      together: palette.lived,
      ahead: palette.accent,
      own: Color.lerp(palette.remaining, scheme.onSurfaceVariant, ownShade)!,
    );
  }

  /// Share of [ColorScheme.onSurfaceVariant] mixed into [own].
  static const double ownShade = 0.3;

  /// Lived side by side so far.
  final Color together;

  /// The shared time ahead.
  final Color ahead;

  /// Each life's own time, before the other was born and after the shared
  /// time ends (one colour, one legend entry).
  final Color own;

  @override
  bool operator ==(Object other) =>
      other is SharedTimeColors &&
      other.together == together &&
      other.ahead == ahead &&
      other.own == own;

  @override
  int get hashCode => Object.hash(together, ahead, own);
}

/// Two lives as horizontal bars on one calendar axis (the user's on top,
/// the friend's below), with a "Today" line, coloured by [colors]: time
/// together so far, shared time ahead, and each life's own time.
/// Bars get an [outline] so their ends stay visible.
class SharedTimePainter extends CustomPainter {
  SharedTimePainter({
    required this.time,
    required this.youLabel,
    required this.themLabel,
    required this.todayLabel,
    required this.colors,
    required this.outline,
    required this.labelColor,
    required this.todayColor,
    this.fontFamily,
  });

  final SharedTime time;
  final String youLabel;
  final String themLabel;
  final String todayLabel;
  final SharedTimeColors colors;
  final Color outline;
  final Color labelColor;
  final Color todayColor;
  final String? fontFamily;

  static const double fontSize = 12;
  static const double todayBand = 20;
  static const double labelHeight = 18;
  static const double barHeight = 16;
  static const double rowGap = 10;
  static const double _todayWidth = 2;
  static const Radius _corner = Radius.circular(barHeight / 2);

  /// The height the painter needs for its two rows.
  static const double preferredHeight =
      todayBand + 2 * (labelHeight + barHeight) + rowGap + 4;

  /// Position (0..1) of [date] on the axis from [start] to [end].
  static double fractionOf(DateTime date, DateTime start, DateTime end) {
    final span = end.difference(start).inMinutes;
    if (span <= 0) return 0;
    return (date.difference(start).inMinutes / span).clamp(0.0, 1.0);
  }

  DateTime get _axisStart =>
      time.userBirthDate.isBefore(time.friendBirthDate)
          ? time.userBirthDate
          : time.friendBirthDate;

  DateTime get _axisEnd => _latest(
      [time.userEnd, time.friendEnd, time.today, _axisStart]);

  static DateTime _latest(List<DateTime> dates) =>
      dates.reduce((a, b) => a.isAfter(b) ? a : b);

  static DateTime _earliest(List<DateTime> dates) =>
      dates.reduce((a, b) => a.isBefore(b) ? a : b);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    double x(DateTime date) =>
        fractionOf(date, _axisStart, _axisEnd) * size.width;

    final userTop = todayBand + labelHeight;
    final friendTop = userTop + barHeight + rowGap + labelHeight;
    _drawRow(canvas, size, x, youLabel, userTop, time.userBirthDate,
        time.userEnd);
    _drawRow(canvas, size, x, themLabel, friendTop, time.friendBirthDate,
        time.friendEnd);
    _drawToday(canvas, size, x(time.today), friendTop + barHeight);
  }

  void _drawRow(Canvas canvas, Size size, double Function(DateTime) x,
      String label, double barTop, DateTime birth, DateTime end) {
    _drawText(canvas, label, Offset(0, barTop - labelHeight), size.width,
        color: labelColor);
    final left = x(birth);
    final right = x(end);
    if (right - left < 1) return;
    final bar = RRect.fromLTRBR(left, barTop, right, barTop + barHeight, _corner);

    canvas.save();
    canvas.clipRRect(bar);
    canvas.drawRRect(bar, Paint()..color = colors.own);
    final livedEnd = _earliest([time.today, end]);
    final overlapStart = _latest([time.userBirthDate, time.friendBirthDate]);
    _fill(canvas, x, barTop, overlapStart, livedEnd, colors.together);
    final aheadStart = _latest([time.today, overlapStart]);
    _fill(canvas, x, barTop, aheadStart, time.sharedEnd, colors.ahead);
    canvas.restore();

    canvas.drawRRect(
      bar,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _fill(Canvas canvas, double Function(DateTime) x, double top,
      DateTime from, DateTime to, Color color) {
    if (!to.isAfter(from)) return;
    canvas.drawRect(
      Rect.fromLTRB(x(from), top, x(to), top + barHeight),
      Paint()..color = color,
    );
  }

  void _drawToday(Canvas canvas, Size size, double todayX, double bottom) {
    final lineX = size.width <= _todayWidth
        ? size.width / 2
        : todayX.clamp(_todayWidth / 2, size.width - _todayWidth / 2);
    canvas.drawLine(
      Offset(lineX, todayBand - 2),
      Offset(lineX, bottom + 2),
      Paint()
        ..color = todayColor
        ..strokeWidth = _todayWidth,
    );
    final text = _layout(todayLabel, size.width, color: todayColor, bold: true);
    final left = (lineX - text.width / 2)
        .clamp(0.0, (size.width - text.width).clamp(0.0, double.infinity));
    text.paint(canvas, Offset(left, 0));
    text.dispose();
  }

  void _drawText(Canvas canvas, String value, Offset offset, double maxWidth,
      {required Color color}) {
    final text = _layout(value, maxWidth, color: color);
    text.paint(canvas, offset);
    text.dispose();
  }

  TextPainter _layout(String value, double maxWidth,
      {required Color color, bool bold = false}) {
    return TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
  }

  @override
  bool shouldRepaint(SharedTimePainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.youLabel != youLabel ||
      oldDelegate.themLabel != themLabel ||
      oldDelegate.todayLabel != todayLabel ||
      oldDelegate.colors != colors ||
      oldDelegate.outline != outline ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.todayColor != todayColor ||
      oldDelegate.fontFamily != fontFamily;
}
