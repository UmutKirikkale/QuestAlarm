import 'player.dart';

/// Admin God Mode tablosu satırı — `users/{uid}`.
class ModeratedUser {
  const ModeratedUser({
    required this.uid,
    required this.player,
    required this.isBanned,
    this.email,
  });

  final String uid;
  final Player player;
  final bool isBanned;
  final String? email;

  factory ModeratedUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final rawPlayer = data['player'];
    Player player;
    if (rawPlayer is Map) {
      final mapped = rawPlayer.map(
        (key, value) => MapEntry(key.toString(), value as dynamic),
      );
      player = Player.fromMap(Map<String, dynamic>.from(mapped));
    } else {
      player = Player.initial();
    }

    final isPro = player.isPro || (data['isPro'] as bool? ?? false);
    final mergedPlayer =
        isPro == player.isPro ? player : player.copyWith(isPro: isPro);

    return ModeratedUser(
      uid: uid,
      player: mergedPlayer,
      isBanned: data['isBanned'] as bool? ?? false,
      email: data['email'] as String?,
    );
  }
}
