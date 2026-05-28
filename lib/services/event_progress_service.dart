import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_progress.dart';
import 'auth_service.dart';
import 'player_service.dart';

/// Oyuncu etkinlik ilerlemesi: `users/{uid}/active_event_progress`.
class EventProgressService {
  EventProgressService._();

  static final EventProgressService instance = EventProgressService._();

  static const String subcollection = 'active_event_progress';

  /// Ücretsiz oyuncuların aynı anda katılabileceği etkinlik sayısı.
  static const int maxFreeActiveEvents = 2;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => AuthService.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _progressRef(String uid) =>
      _db.collection('users').doc(uid).collection(subcollection);

  /// Tüm etkinlik ilerlemelerini canlı dinler.
  Stream<Map<String, EventProgress>> watchAllProgress() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value({});
    }
    return _progressRef(uid).snapshots().map((snapshot) {
      final map = <String, EventProgress>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = EventProgress.fromMap(doc.id, doc.data());
      }
      return map;
    });
  }

  /// Tek etkinlik ilerlemesi.
  Stream<EventProgress> watchProgress(String eventId) {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(EventProgress.empty(eventId));
    }
    return _progressRef(uid).doc(eventId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return EventProgress.empty(eventId);
      }
      return EventProgress.fromMap(eventId, doc.data()!);
    });
  }

  int countActiveEnrollments(Map<String, EventProgress> progressMap) {
    return progressMap.values.where((p) => p.isActiveEnrollment).length;
  }

  /// Etkinliğe katıl — Pro sınırsız, ücretsiz en fazla [maxFreeActiveEvents].
  Future<EventEnrollResult> enrollInEvent(String eventId) async {
    final uid = _uid;
    if (uid == null) {
      return EventEnrollResult.failure('Giriş yapmanız gerekiyor.');
    }

    final player = await PlayerService.instance.loadPlayer();
    final ref = _progressRef(uid).doc(eventId);
    final snap = await ref.get();
    if (snap.exists && snap.data() != null) {
      final existing = EventProgress.fromMap(eventId, snap.data()!);
      if (existing.enrolled) {
        return EventEnrollResult.failure('Bu etkinliğe zaten katıldınız.');
      }
    }

    if (!player.isPro) {
      final allSnap = await _progressRef(uid).get();
      var active = 0;
      for (final doc in allSnap.docs) {
        final p = EventProgress.fromMap(doc.id, doc.data());
        if (p.isActiveEnrollment) active++;
      }
      if (active >= maxFreeActiveEvents) {
        return EventEnrollResult.failure(
          'Pro olmadan en fazla $maxFreeActiveEvents etkinliğe katılabilirsiniz. '
          'Pro üyelikle sınırsız katılım!',
        );
      }
    }

    await ref.set({
      'eventId': eventId,
      'currentProgress': snap.exists
          ? (snap.data()?['currentProgress'] as num?)?.toInt() ?? 0
          : 0,
      'completed': false,
      'rewardClaimed': false,
      'enrolled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return EventEnrollResult.success();
  }

  /// Sabah zaferi sonrası kayıtlı (enrolled) aktif etkinliklerde ilerlemeyi +1 artırır.
  Future<void> incrementOnVictory() async {
    final uid = _uid;
    if (uid == null) return;

    final eventsSnap = await _db.collection('global_events').get();
    if (eventsSnap.docs.isEmpty) return;

    for (final eventDoc in eventsSnap.docs) {
      final data = eventDoc.data();
      final isActive = data['isActive'] as bool? ?? true;
      if (!isActive) continue;

      final target = (data['targetCount'] as num?)?.toInt() ?? 1;
      await _incrementProgress(uid, eventDoc.id, target);
    }
  }

  Future<void> _incrementProgress(
    String uid,
    String eventId,
    int targetCount,
  ) async {
    final ref = _progressRef(uid).doc(eventId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;

      final current = EventProgress.fromMap(eventId, snap.data()!);
      if (!current.enrolled || current.rewardClaimed) return;

      final next = (current.currentProgress + 1).clamp(0, targetCount);
      final completed = next >= targetCount;

      tx.set(ref, {
        'eventId': eventId,
        'currentProgress': next,
        'completed': completed,
        'rewardClaimed': current.rewardClaimed,
        'enrolled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Ödülü al: altın ekle, etkinliği tamamlandı işaretle.
  Future<EventClaimResult> claimReward({
    required String eventId,
    required int rewardGold,
    required int targetCount,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return EventClaimResult.failure('Giriş yapmanız gerekiyor.');
    }

    final ref = _progressRef(uid).doc(eventId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      return EventClaimResult.failure('İlerleme bulunamadı.');
    }

    final progress = EventProgress.fromMap(eventId, snap.data()!);
    if (progress.rewardClaimed) {
      return EventClaimResult.failure('Ödül zaten alındı.');
    }
    if (progress.currentProgress < targetCount) {
      return EventClaimResult.failure('Hedef henüz tamamlanmadı.');
    }

    await PlayerService.instance.addGold(rewardGold);
    await ref.set({
      'eventId': eventId,
      'currentProgress': progress.currentProgress,
      'completed': true,
      'rewardClaimed': true,
      'enrolled': progress.enrolled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return EventClaimResult.success(rewardGold);
  }
}

class EventEnrollResult {
  const EventEnrollResult._({required this.success, this.message});

  final bool success;
  final String? message;

  factory EventEnrollResult.success() =>
      const EventEnrollResult._(success: true);

  factory EventEnrollResult.failure(String message) =>
      EventEnrollResult._(success: false, message: message);
}

class EventClaimResult {
  const EventClaimResult._({
    required this.success,
    this.message,
    this.goldAwarded,
  });

  final bool success;
  final String? message;
  final int? goldAwarded;

  factory EventClaimResult.success(int gold) => EventClaimResult._(
        success: true,
        goldAwarded: gold,
      );

  factory EventClaimResult.failure(String message) => EventClaimResult._(
        success: false,
        message: message,
      );
}
