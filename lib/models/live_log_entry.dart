/// Firestore `live_logs` kaydı.
class LiveLogEntry {
  const LiveLogEntry({
    required this.id,
    required this.message,
    required this.createdAtMs,
  });

  final String id;
  final String message;
  final int createdAtMs;

  factory LiveLogEntry.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAtMs'] as num?;
    return LiveLogEntry(
      id: id,
      message: map['message'] as String? ?? '',
      createdAtMs: ts?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  String formattedTime() {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '[$h:$m]';
  }
}
