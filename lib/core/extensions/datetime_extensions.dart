extension DateTimeFormatting on DateTime {
  /// Returns e.g. "Mon, Jan 6"
  String get weekdayMonthDay {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final wd = weekdays[weekday - 1];
    final mo = months[month - 1];
    return '$wd, $mo $day';
  }

  /// Returns e.g. "9:05 AM"
  String get timeOfDay {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  /// Returns a human-readable relative label like "Today", "Yesterday", or "Jan 6".
  String get relativeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $day${year != now.year ? ', $year' : ''}';
  }

  /// Duration between this and another DateTime as "Xh Ym" string.
  String durationUntil(DateTime end) {
    final diff = end.difference(this).abs();
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

extension DurationFormatting on Duration {
  /// Returns "MM:SS" for durations under an hour, "H:MM:SS" otherwise.
  String get formatted {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h == 0) return '$m:$s';
    return '$h:$m:$s';
  }
}
