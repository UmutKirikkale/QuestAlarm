import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player.dart';

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
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'player': player.toMap(),
        'clientUpdatedAtMs': updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<CloudPlayerData?> loadPlayerData(String uid) async {
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
        player: Player.fromMap(mapped),
        updatedAtMs: updatedAtMs,
      );
    }
    return null;
  }
}
