import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/event_mapping/firestore_teaser_repository.dart';

void main() {
  group('FirestoreTeaserRepository argument validation', () {
    final repo = FirestoreTeaserRepository();

    test('rejects empty userId when tracking teaser', () {
      expect(
        () => repo.watchTrackedTeaserIds(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.watchTrackedTeaserIds('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty teaserId when tracking teaser', () {
      expect(
        () => repo.watchTeaserTrackerCount(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.watchIsTrackingTeaser(userId: 'user-1', teaserId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.setTrackingTeaser(
          userId: 'user-1',
          teaserId: '',
          isTracking: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
