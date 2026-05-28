import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/live_log_entry.dart';
import 'auth_service.dart';

/// Dünya geneli canlı olay akışı — `live_logs`.
class LiveLogService {
  LiveLogService._();

  static final LiveLogService instance = LiveLogService._();

  static const String collection = 'live_logs';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LiveLogEntry>> watchLogs({int limit = 80}) {
    return _db
        .collection(collection)
        .orderBy('createdAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LiveLogEntry.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> publish(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    try {
      await _db.collection(collection).add({
        'message': trimmed,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
        'uid': AuthService.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('LiveLogService.publish failed: $e');
    }
  }

  Future<void> logMonsterDefeated({
    required String monsterName,
    String? playerLabel,
  }) async {
    final who = playerLabel ?? _defaultPlayerLabel();
    await publish('$who uykulu $monsterName\'ı kesti!');
  }

  Future<void> logItemPurchased({
    required String itemName,
    String? playerLabel,
  }) async {
    final who = playerLabel ?? _defaultPlayerLabel();
    await publish('$who mağazadan $itemName aldı.');
  }

  Future<void> logWeaponBroken({String? playerLabel}) {
    final who = playerLabel ?? _defaultPlayerLabel();
    return publish('$who serisi bozuldu — kılıcı kırıldı!');
  }

  String _defaultPlayerLabel() {
    final user = AuthService.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final uid = user?.uid;
    if (uid != null && uid.length >= 6) {
      return 'Oyuncu ${uid.substring(0, 6)}';
    }
    return 'Bir kahraman';
  }
}
