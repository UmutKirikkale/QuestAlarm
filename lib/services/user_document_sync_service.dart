import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/player.dart';
import 'auth_service.dart';
import 'player_service.dart';

/// `users/{uid}` için tek Firestore dinleyicisi — kota dostu, değişimde tetiklenir.
class UserDocumentSnapshot {
  const UserDocumentSnapshot({
    required this.gold,
    required this.diamonds,
    required this.isBanned,
    required this.clientUpdatedAtMs,
    this.player,
  });

  final int gold;
  final int diamonds;
  final bool isBanned;
  final int clientUpdatedAtMs;
  final Player? player;

  static UserDocumentSnapshot empty() => const UserDocumentSnapshot(
        gold: 0,
        diamonds: 0,
        isBanned: false,
        clientUpdatedAtMs: 0,
      );

  factory UserDocumentSnapshot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return UserDocumentSnapshot.empty();

    Player? player;
    final rawPlayer = data['player'];
    if (rawPlayer is Map) {
      final mapped = rawPlayer.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      player = Player.fromMap(Map<String, dynamic>.from(mapped));
    }

    return UserDocumentSnapshot(
      gold: player?.gold ?? 0,
      diamonds: player?.diamonds ?? 0,
      isBanned: data['isBanned'] as bool? ?? false,
      clientUpdatedAtMs: (data['clientUpdatedAtMs'] as num?)?.toInt() ?? 0,
      player: player,
    );
  }
}

class UserDocumentSyncService {
  UserDocumentSyncService._();

  static final UserDocumentSyncService instance = UserDocumentSyncService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StreamController<UserDocumentSnapshot> _controller =
      StreamController<UserDocumentSnapshot>.broadcast();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  UserDocumentSnapshot _latest = UserDocumentSnapshot.empty();

  Stream<UserDocumentSnapshot> get stream => _controller.stream;

  UserDocumentSnapshot get latest => _latest;

  bool get isAttached => _sub != null;

  void attach(String uid) {
    if (_uid == uid && _sub != null) return;
    detach();
    _uid = uid;
    _sub = _db.collection('users').doc(uid).snapshots().listen(
      _onSnapshot,
      onError: (Object e) => debugPrint('UserDocumentSync error: $e'),
    );
  }

  void detach() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _latest = UserDocumentSnapshot.empty();
  }

  void _onSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final snap = UserDocumentSnapshot.fromFirestore(doc);
    _latest = snap;
    if (!_controller.isClosed) {
      _controller.add(snap);
    }
    if (snap.player != null) {
      unawaited(PlayerService.instance.mergeFromCloudIfNewer(snap));
    }
  }

  /// Giriş yapmış kullanıcı için dinleyiciyi başlatır (idempotent).
  void attachCurrentUser() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) attach(uid);
  }
}
