import 'package:cosmic_mirror/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

StoreProduct _product(
  String id,
  double price, {
  IntroductoryPrice? intro,
}) =>
    StoreProduct(
      id,
      'desc',
      'title',
      price,
      '\$${price.toStringAsFixed(2)}',
      'USD',
      introductoryPrice: intro,
    );

PaywallPlan _plan(PackageType type, StoreProduct product, {int? trialDays}) =>
    PaywallPlan(
      package: Package(
        type.name,
        type,
        product,
        const PresentedOfferingContext('default', null, null),
      ),
      freeTrialDays: trialDays,
    );

void main() {
  group('freeTrialDays', () {
    test('3-day free trial', () {
      final p = _product(
        'yearly',
        39.99,
        intro: const IntroductoryPrice(0, r'$0.00', 'P3D', 1, PeriodUnit.day, 3),
      );
      expect(freeTrialDays(p), 3);
    });

    test('1-week free trial counts as 7 days', () {
      final p = _product(
        'yearly',
        39.99,
        intro: const IntroductoryPrice(0, r'$0.00', 'P1W', 1, PeriodUnit.week, 1),
      );
      expect(freeTrialDays(p), 7);
    });

    test('paid intro offer is not a free trial', () {
      final p = _product(
        'yearly',
        39.99,
        intro:
            const IntroductoryPrice(0.99, r'$0.99', 'P1M', 1, PeriodUnit.month, 1),
      );
      expect(freeTrialDays(p), isNull);
    });

    test('no intro offer', () {
      expect(freeTrialDays(_product('monthly', 6.99)), isNull);
    });
  });

  group('PaywallOffering', () {
    final monthly = _plan(PackageType.monthly, _product('monthly', 6.99));
    final annual = _plan(
      PackageType.annual,
      _product('yearly', 39.99),
      trialDays: 3,
    );

    test('defaults to the annual plan', () {
      final o = PaywallOffering(plans: [monthly, annual]);
      expect(o.defaultPlan, same(annual));
      expect(o.annual!.hasFreeTrial, isTrue);
      expect(o.monthly!.hasFreeTrial, isFalse);
    });

    test('annual savings vs 12 x monthly', () {
      final o = PaywallOffering(plans: [monthly, annual]);
      // 39.99 / (6.99 * 12) = 0.4768 → 52% saving.
      expect(o.annualSavings, closeTo(0.523, 0.001));
    });

    test('no savings badge without both plans', () {
      expect(PaywallOffering(plans: [annual]).annualSavings, isNull);
    });

    test('unavailable offering has no plans', () {
      const o = PaywallOffering.unavailable();
      expect(o.unavailable, isTrue);
      expect(o.defaultPlan, isNull);
    });
  });
}
