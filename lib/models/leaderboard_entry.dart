import 'package:cloud_firestore/cloud_firestore.dart';

import 'player.dart';

/// Küresel liderlik tablosu satırı — `users/{uid}`.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.streak,
    required this.level,
    required this.xp,
    required this.showOnLeaderboard,
    required this.isBanned,
    this.isPro = false,
  });

  final String uid;
  final String displayName;
  final int streak;
  final int level;
  final int xp;
  final bool showOnLeaderboard;
  final bool isBanned;
  final bool isPro;

  String get shortUid =>
      uid.length > 10 ? '${uid.substring(0, 10)}…' : uid;

  factory LeaderboardEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawPlayer = data['player'];
    Player? player;
    if (rawPlayer is Map) {
      final mapped = rawPlayer.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      player = Player.fromMap(Map<String, dynamic>.from(mapped));
    }

    final streak = (data['streak'] as num?)?.toInt() ?? player?.streak ?? 0;
    final level = (data['level'] as num?)?.toInt() ?? player?.level ?? 1;
    final xp = (data['xp'] as num?)?.toInt() ??
        (data['currentXP'] as num?)?.toInt() ??
        player?.currentXP ??
        0;

    final name = data['displayName'] as String? ??
        player?.characterClassId ??
        'Kahraman';

    return LeaderboardEntry(
      uid: doc.id,
      displayName: name,
      streak: streak,
      level: level,
      xp: xp,
      showOnLeaderboard: data['showOnLeaderboard'] as bool? ?? true,
      isBanned: data['isBanned'] as bool? ?? false,
      isPro: player?.isPro ?? (data['isPro'] as bool? ?? false),
    );
  }
}

/// Oyuncunun küresel sıralama özeti.
class LeaderboardSelfRank {
  const LeaderboardSelfRank({
    required this.rank,
    required this.streak,
    required this.level,
    required this.xp,
    required this.visibleOnLeaderboard,
  });

  final int rank;
  final int streak;
  final int level;
  final int xp;
  final bool visibleOnLeaderboard;
}
