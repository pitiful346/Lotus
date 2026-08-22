import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/event_mapping/firestore_promoter_follow_repository.dart';

void main() {
  group('FirestorePromoterFollowRepository argument validation', () {
    test('rejects empty or invalid userId', () {
      final repository = FirestorePromoterFollowRepository();

      expect(
        () => repository.watchIsFollowing(userId: '', organizerId: 'org-1'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.watchIsFollowing(
          userId: 'users/invalid/nested',
          organizerId: 'org-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty or invalid organizerId', () {
      final repository = FirestorePromoterFollowRepository();

      expect(
        () => repository.watchIsFollowing(userId: 'user-1', organizerId: ''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.watchIsFollowing(
          userId: 'user-1',
          organizerId: 'too/many/nested/levels/organizers/1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
