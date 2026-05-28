import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';
import '../utils/firestore_resilience.dart';

class CloudPlayerData {
  const CloudPlayerData({
    required this.player,
    required this.updatedAtMs,
  });

  final Player player;
  final int updatedAtMs;
}

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePlayerData(
    String uid,
    Player player, {
    int? updatedAtMs,
    String? displayName,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final existing = await docRef.get();
    final existingData = existing.data();
    final showOnLeaderboard =
        existingData?['showOnLeaderboard'] as bool? ?? true;

    await withFirestoreVoidTimeout(
      docRef.set(
        {
          'player': player.toMap(),
          'isPro': player.isPro,
          'streak': player.streak,
          'level': player.level,
          'xp': player.currentXP,
          'showOnLeaderboard': showOnLeaderboard,
          if (displayName != null && displayName.trim().isNotEmpty)
            'displayName': displayName.trim(),
          'clientUpdatedAtMs':
              updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ),
      debugLabel: 'savePlayerData',
    );
  }

  Future<CloudPlayerData?> loadPlayerData(String uid) async {
    return withFirestoreTimeout<CloudPlayerData?>(
      () async {
        final doc = await _firestore.collection('users').doc(uid).get();
        final data = doc.data();
        if (data == null) return null;
        final rawPlayer = data['player'];
        if (rawPlayer is Map) {
          final mapped = rawPlayer.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final updatedAtMs = (data['clientUpdatedAtMs'] as num?)?.toInt() ?? 0;
          return CloudPlayerData(
            player: Player.fromMap(Map<String, dynamic>.from(mapped)),
            updatedAtMs: updatedAtMs,
          );
        }
        return null;
      }(),
      debugLabel: 'loadPlayerData',
      fallback: null,
    );
  }

  Future<void> deleteUserData(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
