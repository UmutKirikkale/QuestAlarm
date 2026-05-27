import 'package:flutter_test/flutter_test.dart';

import 'package:quest_alarm/models/player.dart';

void main() {
  test('Player initial defaults are valid', () {
    final player = Player.initial();
    expect(player.level, 1);
    expect(player.characterClass, CharacterClass.warrior);
    expect(player.equippedWeapon?.durability, 100);
  });
}
