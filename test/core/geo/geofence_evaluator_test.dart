import 'package:flutter_test/flutter_test.dart';

import 'package:family_essentials_mobile/core/geo/geofence_evaluator.dart';

void main() {
  const evaluator = GeofenceEvaluator();
  const center = GeoPoint(23.8103, 90.4125);

  test('measures the distance between two points', () {
    // 0.01 degrees of latitude is ~1112 m at any longitude.
    const north = GeoPoint(23.8203, 90.4125);

    expect(evaluator.distanceMeters(center, north), closeTo(1112, 15));
  });

  test('detects being within a radius', () {
    expect(
      evaluator.isWithin(center, 300, const GeoPoint(23.8110, 90.4130)),
      isTrue,
    );
    expect(
      evaluator.isWithin(center, 300, const GeoPoint(23.8300, 90.4125)),
      isFalse,
    );
  });

  test('emits enter when crossing into a fence', () {
    final transitions = evaluator.evaluate(
      [(placeId: 7, point: center, radius: 300)],
      const GeoPoint(23.8105, 90.4125),
      const {},
    );

    expect(transitions, hasLength(1));
    expect(transitions.single.placeId, 7);
    expect(transitions.single.entered, isTrue);
  });

  test('emits exit when leaving a fence', () {
    final transitions = evaluator.evaluate(
      [(placeId: 7, point: center, radius: 300)],
      const GeoPoint(23.8300, 90.4125),
      const {7: true},
    );

    expect(transitions, hasLength(1));
    expect(transitions.single.entered, isFalse);
  });

  test('emits nothing while staying inside or outside', () {
    final places = [(placeId: 7, point: center, radius: 300)];

    expect(
      evaluator.evaluate(places, const GeoPoint(23.8105, 90.4125), const {
        7: true,
      }),
      isEmpty,
    );
    expect(
      evaluator.evaluate(places, const GeoPoint(23.8300, 90.4125), const {
        7: false,
      }),
      isEmpty,
    );
  });
}
