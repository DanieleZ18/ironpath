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
