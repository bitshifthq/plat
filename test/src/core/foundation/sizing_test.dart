import 'package:flutter_test/flutter_test.dart';
import 'package:plat/src/core/foundation/foundation.dart';

void main() {
  group('PlatExtent / PlatSize', () {
    group('Pixels', () {
      test('stores non-negative values and compares by type and value', () {
        expect((const PlatExtent.pixel(120) as Pixels).value, 120);
        expect(const PlatExtent.pixel(0), isA<Pixels>());
        expect(const PlatExtent.pixel(120), const PlatExtent.pixel(120));
        expect(
          const PlatExtent.pixel(120).hashCode,
          const PlatExtent.pixel(120).hashCode,
        );
        expect(const PlatExtent.pixel(120), isNot(const PlatExtent.pixel(80)));
        expect(
          const PlatExtent.pixel(0.5),
          isNot(const PlatExtent.fraction(0.5)),
        );
      });

      test('rejects negative values', () {
        expect(() => PlatExtent.pixel(-1), throwsA(isA<AssertionError>()));
      });

      test('formats with the pixel suffix', () {
        expect(const PlatExtent.pixel(120).toString(), '120.0px');
      });
    });

    group('Fraction', () {
      test('stores bounded values and compares by type and value', () {
        expect((const PlatExtent.fraction(0.3) as Fraction).value, 0.3);
        expect(const PlatExtent.fraction(0), isA<Fraction>());
        expect(const PlatExtent.fraction(1), isA<Fraction>());
        expect(const PlatExtent.fraction(0.3), const PlatExtent.fraction(0.3));
        expect(
          const PlatExtent.fraction(0.3).hashCode,
          const PlatExtent.fraction(0.3).hashCode,
        );
        expect(
          const PlatExtent.fraction(0.3),
          isNot(const PlatExtent.fraction(0.4)),
        );
      });

      test('rejects values outside the 0..1 range', () {
        expect(() => PlatExtent.fraction(-0.1), throwsA(isA<AssertionError>()));
        expect(() => PlatExtent.fraction(1.5), throwsA(isA<AssertionError>()));
      });

      test('formats as a percentage', () {
        expect(const PlatExtent.fraction(0.3).toString(), '30.0%');
      });
    });

    group('AutoExtent', () {
      test('compares as a single value type', () {
        expect(const PlatExtent.auto(), const PlatExtent.auto());
        expect(
          const PlatExtent.auto().hashCode,
          const PlatExtent.auto().hashCode,
        );
        expect(const PlatExtent.auto(), isNot(const PlatExtent.pixel(0)));
      });

      test('formats as auto', () {
        expect(const PlatExtent.auto().toString(), 'auto');
      });
    });

    group('FixedSize', () {
      test('stores wrapped extents and compares by wrapped value', () {
        const fixed = PlatSize.fixed(.pixel(200));

        expect((fixed as FixedSize).extent, const PlatExtent.pixel(200));
        expect(fixed, const PlatSize.fixed(.pixel(200)));
        expect(fixed, isNot(const PlatSize.fixed(.pixel(120))));
        expect(fixed, isNot(const PlatSize.resizable(initial: .pixel(200))));
      });

      test('rejects an auto extent', () {
        expect(
          () => PlatSize.fixed(const PlatExtent.auto()),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('FlexibleSize', () {
      test('PlatSize.auto uses auto bounds everywhere', () {
        const size = PlatSize.auto() as FlexibleSize;

        expect(size.initial, const PlatExtent.auto());
        expect(size.min, const PlatExtent.auto());
        expect(size.max, const PlatExtent.auto());
      });

      test('preserves mixed-unit bounds', () {
        const size =
            PlatSize.resizable(initial: .fraction(0.3), min: .pixel(200))
                as FlexibleSize;

        expect(size.initial, const PlatExtent.fraction(0.3));
        expect(size.min, const PlatExtent.pixel(200));
        expect(size.max, const PlatExtent.auto());
      });

      test('copyWith overrides only the provided bound', () {
        const original =
            PlatSize.resizable(initial: .fraction(0.3), min: .pixel(200))
                as FlexibleSize;

        final updated = original.copyWith(max: const .fraction(0.5));

        expect(updated.initial, const PlatExtent.fraction(0.3));
        expect(updated.min, const PlatExtent.pixel(200));
        expect(updated.max, const PlatExtent.fraction(0.5));
      });

      test('compares all three bounds', () {
        expect(
          const PlatSize.resizable(initial: .pixel(280)),
          const PlatSize.resizable(initial: .pixel(280)),
        );
        expect(
          const PlatSize.resizable(initial: .pixel(280)),
          isNot(const PlatSize.resizable(initial: .pixel(120))),
        );
      });

      test('treats PlatSize.auto as the explicit auto-bounded form', () {
        expect(const PlatSize.auto(), const PlatSize.resizable());
      });
    });
  });
}
