// Small formatting helpers (no intl dependency for the MVP).

String pad2(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) =>
    '${d.year}-${pad2(d.month)}-${pad2(d.day)} ${pad2(d.hour)}:${pad2(d.minute)}';

String fmtDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '${s}s';
  return '${m}m ${pad2(s)}s';
}

String fmtWeight(double w) =>
    w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

const _weekdaysZh = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// Friendly day header: "10月29日 · 周四" / "Thu, Oct 29".
String fmtDayHeader(DateTime d, bool zh) => zh
    ? '${d.month}月${d.day}日 · ${_weekdaysZh[d.weekday - 1]}'
    : '${_weekdaysEn[d.weekday - 1]}, ${_monthsEn[d.month - 1]} ${d.day}';

/// Short month label for date blobs: "10月" / "Oct".
String fmtMonthShort(DateTime d, bool zh) =>
    zh ? '${d.month}月' : _monthsEn[d.month - 1];

/// Clock time only: "19:05".
String fmtTime(DateTime d) => '${pad2(d.hour)}:${pad2(d.minute)}';

/// Compact day label for chart axes: "10/27" (both languages).
String fmtMonthDay(DateTime d) => '${d.month}/${d.day}';

/// Training time as hours and minutes: "3 h 20 min" / "3小时20分".
String fmtHoursMinutes(int seconds, bool zh) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (zh) return h == 0 ? '$m分钟' : '$h小时$m分';
  return h == 0 ? '$m min' : '$h h $m min';
}
