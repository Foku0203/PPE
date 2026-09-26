import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date formatting. Thai uses the Buddhist era (พ.ศ.) as is customary.
class Fmt {
  static String _tag(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

  static String date(BuildContext context, DateTime? value) {
    if (value == null) return '-';
    final tag = _tag(context);
    if (tag.startsWith('th')) {
      return '${DateFormat('d MMM', tag).format(value)} ${value.year + 543}';
    }
    return DateFormat.yMMMd(tag).format(value);
  }

  static String dateTime(BuildContext context, DateTime? value) {
    if (value == null) return '-';
    return '${date(context, value)} ${DateFormat.Hm(_tag(context)).format(value)}';
  }

  static String time(BuildContext context, DateTime? value) => value == null ? '-' : DateFormat.Hms(_tag(context)).format(value);

  static String number(BuildContext context, num value) => NumberFormat.decimalPattern(_tag(context)).format(value);

  /// "5 min", "3 h", "2 d" style relative age.
  static String relative(BuildContext context, DateTime? value) {
    if (value == null) return '';
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return '<1m';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return date(context, value);
  }
}
