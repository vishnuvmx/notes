/// Simple, robust date formatter utility for Tack.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    final isYesterday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day - 1 == dateTime.day;

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else {
      final day = dateTime.day;
      final month = _months[dateTime.month - 1];
      if (now.year == dateTime.year) {
        return '$day $month, $timeStr';
      } else {
        return '$day $month ${dateTime.year}, $timeStr';
      }
    }
  }

  static String formatShortDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    return '$day $month $year';
  }

  /// Formats date with ordinal suffix matching mockup (e.g., "4th Jan 2050")
  static String formatOrdinalDate(DateTime dateTime) {
    final day = dateTime.day;
    final suffix = _getOrdinalSuffix(day);
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    return '$day$suffix $month $year';
  }

  static String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
