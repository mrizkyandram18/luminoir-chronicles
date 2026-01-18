import 'package:flutter_test/flutter_test.dart';
import 'package:luminoir_chronicles/game/raid/models/combat_archetypes.dart';

void main() {
  group('Faction restrain relationships', () {
    test('follows Thunder > Earth > Water > Fire > Wind > Thunder cycle', () {
      expect(Faction.thunder.restrains(), Faction.earth);
      expect(Faction.earth.restrains(), Faction.water);
      expect(Faction.water.restrains(), Faction.fire);
      expect(Faction.fire.restrains(), Faction.wind);
      expect(Faction.wind.restrains(), Faction.thunder);
    });

    test('YinYang has no advantage or disadvantage', () {
      expect(Faction.yinYang.restrains(), isNull);
      expect(Faction.yinYang.restrainedBy(), isNull);
      expect(Faction.yinYang.hasAdvantageOver(Faction.fire), isFalse);
      expect(Faction.yinYang.hasDisadvantageAgainst(Faction.fire), isFalse);
    });

    test('hasAdvantageOver and hasDisadvantageAgainst are consistent', () {
      expect(Faction.thunder.hasAdvantageOver(Faction.earth), isTrue);
      expect(Faction.earth.hasDisadvantageAgainst(Faction.thunder), isTrue);

      expect(Faction.fire.hasAdvantageOver(Faction.wind), isTrue);
      expect(Faction.wind.hasDisadvantageAgainst(Faction.fire), isTrue);
    });

    test('defenderEffect applies restrainedEffect when attacker has advantage',
        () {
      final effect = FactionRelations.defenderEffect(
        attacker: Faction.thunder,
        defender: Faction.earth,
      );

      expect(effect.damageTakenMultiplier, closeTo(1.3, 0.0001));
      expect(effect.accuracyMultiplier, closeTo(0.85, 0.0001));
    });

    test('defenderEffect is neutral when there is no advantage', () {
      final effect = FactionRelations.defenderEffect(
        attacker: Faction.fire,
        defender: Faction.earth,
      );

      expect(effect.damageTakenMultiplier, 1.0);
      expect(effect.accuracyMultiplier, 1.0);
    });
  });

  group('CombatClass enum', () {
    test('defines the expected unit classes', () {
      expect(
        CombatClass.values,
        containsAll(<CombatClass>[
          CombatClass.warrior,
          CombatClass.mage,
          CombatClass.support,
          CombatClass.ranger,
          CombatClass.assassin,
        ]),
      );
    });
  });
}
