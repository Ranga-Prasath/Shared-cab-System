class RideFormatters {
  RideFormatters._();

  static String safeInitial(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '?';
    return normalized[0].toUpperCase();
  }

  static String firstName(String? value, {String fallback = 'there'}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return fallback;
    return normalized.split(RegExp(r'\s+')).first;
  }

  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String departureLabel(DateTime time, {DateTime? now}) {
    final diff = time.difference(now ?? DateTime.now());
    if (diff.isNegative) return 'Departing now';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
