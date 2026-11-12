import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people/lifespan_ring.dart';

void main() {
  test('ofAge divides age by lifespan', () {
    expect(const LifespanRing.ofAge(age: 40, lifespanYears: 80).progress, 0.5);
  });

  test('ofAge treats a zero lifespan as fully lived (no division by zero)', () {
    expect(const LifespanRing.ofAge(age: 0, lifespanYears: 0).progress, 1.0);
    expect(const LifespanRing.ofAge(age: 30, lifespanYears: 0).progress, 1.0);
  });
}
