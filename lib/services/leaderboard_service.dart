import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';
import 'auth_service.dart';

enum LeaderboardSort { streak, level }

/// Küresel liderlik tablosu — `users` koleksiyonu.
class LeaderboardService {
  LeaderboardService._();

  static final LeaderboardService instance = LeaderboardService._();

  static const int topLimit = 50;

  /// Sorgu için fazladan çekilen kayıt (banlı/gizli filtre sonrası 50'ye tamamlamak).
  static const int _fetchBuffer = 80;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Query<Map<String, dynamic>> _baseEligibleQuery() {
    return _users.where('showOnLeaderboard', isEqualTo: true);
  }

  List<LeaderboardEntry> _filterEligible(
    List<LeaderboardEntry> entries, {
    int max = topLimit,
  }) {
    return entries
        .where((e) => e.showOnLeaderboard && !e.isBanned)
        .take(max)
        .toList();
  }

  /// En yüksek seri — canlı akış.
  Stream<List<LeaderboardEntry>> watchTopByStreak() {
    return _baseEligibleQuery()
        .orderBy('streak', descending: true)
        .limit(_fetchBuffer)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(LeaderboardEntry.fromFirestore)
          .toList(growable: false);
      return _filterEligible(list);
    });
  }

  /// En yüksek seviye + XP — canlı akış.
  Stream<List<LeaderboardEntry>> watchTopByLevel() {
    return _baseEligibleQuery()
        .orderBy('level', descending: true)
        .orderBy('xp', descending: true)
        .limit(_fetchBuffer)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(LeaderboardEntry.fromFirestore)
          .toList(growable: false);
      return _filterEligible(list);
    });
  }

  /// Admin: tüm oyuncular (gizliler dahil).
  Stream<List<LeaderboardEntry>> watchAllForModeration({
    LeaderboardSort sort = LeaderboardSort.streak,
  }) {
    final query = sort == LeaderboardSort.streak
        ? _users.orderBy('streak', descending: true).limit(_fetchBuffer)
        : _users
            .orderBy('level', descending: true)
            .orderBy('xp', descending: true)
            .limit(_fetchBuffer);

    return query.snapshots().map(
          (snap) => snap.docs.map(LeaderboardEntry.fromFirestore).toList(),
        );
  }

  Future<LeaderboardSelfRank?> fetchSelfRank(LeaderboardSort sort) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final me = LeaderboardEntry.fromFirestore(doc);
    if (!me.showOnLeaderboard || me.isBanned) {
      return LeaderboardSelfRank(
        rank: 0,
        streak: me.streak,
        level: me.level,
        xp: me.xp,
        visibleOnLeaderboard: false,
      );
    }

    try {
      final rank = sort == LeaderboardSort.streak
          ? await _rankByStreak(me.streak)
          : await _rankByLevel(me.level, me.xp);
      return LeaderboardSelfRank(
        rank: rank,
        streak: me.streak,
        level: me.level,
        xp: me.xp,
        visibleOnLeaderboard: true,
      );
    } catch (e) {
      debugPrint('Leaderboard self rank: $e');
      return LeaderboardSelfRank(
        rank: 0,
        streak: me.streak,
        level: me.level,
        xp: me.xp,
        visibleOnLeaderboard: true,
      );
    }
  }

  Future<int> _rankByStreak(int myStreak) async {
    final higher = await _baseEligibleQuery()
        .where('isBanned', isEqualTo: false)
        .where('streak', isGreaterThan: myStreak)
        .count()
        .get();
    return (higher.count ?? 0) + 1;
  }

  Future<int> _rankByLevel(int myLevel, int myXp) async {
    final higherLevel = await _baseEligibleQuery()
        .where('isBanned', isEqualTo: false)
        .where('level', isGreaterThan: myLevel)
        .count()
        .get();

    final sameLevelHigherXp = await _baseEligibleQuery()
        .where('isBanned', isEqualTo: false)
        .where('level', isEqualTo: myLevel)
        .where('xp', isGreaterThan: myXp)
        .count()
        .get();

    return (higherLevel.count ?? 0) + (sameLevelHigherXp.count ?? 0) + 1;
  }

  Future<void> setShowOnLeaderboard(String uid, bool show) async {
    await _users.doc(uid).set(
      {'showOnLeaderboard': show},
      SetOptions(merge: true),
    );
  }
}
