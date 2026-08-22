import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_promoter_profile_screen.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  final organizer = EventOrganizer(
    id: 'organizers/org-1',
    name: 'Lotus Events',
    legalName: 'Lotus Entertainment Lda',
    description: 'A melhor curadoria de eventos culturais e de música eletrónica em Portugal.',
    websiteUri: Uri.parse('https://lotus.pt'),
    instagramUri: Uri.parse('https://instagram.com/lotusevents'),
    isVerified: true,
    followerCount: 42,
  );

  final upcomingEvent = Event(
    id: 'events/event-1',
    title: 'Noite Eletrónica',
    description: 'Evento próximo',
    categories: [EventCategory(id: 'musica', label: 'Música')],
    location: EventLocation(displayName: 'Porto'),
    startsAt: DateTime.utc(2026, 9, 1),
    organizer: organizer,
  );

  final pastEvent = Event(
    id: 'events/event-2',
    title: 'Festival de Abertura',
    description: 'Evento passado',
    categories: [EventCategory(id: 'cultura', label: 'Cultura')],
    location: EventLocation(displayName: 'Lisboa'),
    startsAt: DateTime.utc(2026, 8, 1),
    organizer: organizer,
  );

  testWidgets('promoter profile renders organizer info, stats, and verified badge', (tester) async {
    final followRepo = _FakeFollowRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusPromoterProfileScreen(
          organizer: organizer,
          userId: 'user-1',
          followRepository: followRepo,
          eventsStream: Stream.value([upcomingEvent, pastEvent]),
          now: () => DateTime.utc(2026, 8, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lotus Events'), findsOneWidget);
    expect(find.text('Lotus Entertainment Lda'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.text('A melhor curadoria de eventos culturais e de música eletrónica em Portugal.'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Seguidores'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Próximos (1)'), findsOneWidget);
    expect(find.text('Anteriores (1)'), findsOneWidget);
    expect(find.text('Noite Eletrónica'), findsOneWidget);
  });

  testWidgets('follow button toggles state when tapped', (tester) async {
    final followRepo = _FakeFollowRepository(initialFollowing: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusPromoterProfileScreen(
          organizer: organizer,
          userId: 'user-1',
          followRepository: followRepo,
          eventsStream: Stream.value([upcomingEvent]),
          now: () => DateTime.utc(2026, 8, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seguir'), findsOneWidget);

    await tester.tap(find.byKey(const Key('promoter-follow-btn')));
    await tester.pumpAndSettle();

    expect(followRepo.lastSetUserId, 'user-1');
    expect(followRepo.lastSetOrganizerId, 'org-1');
    expect(followRepo.lastSetIsFollowing, true);
  });

  testWidgets('unauthenticated user sees snackbar on follow attempt', (tester) async {
    final followRepo = _FakeFollowRepository(initialFollowing: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusPromoterProfileScreen(
          organizer: organizer,
          userId: '',
          followRepository: followRepo,
          eventsStream: Stream.value([upcomingEvent]),
          now: () => DateTime.utc(2026, 8, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('promoter-follow-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sessão para seguires promotores.'), findsOneWidget);
    expect(followRepo.lastSetUserId, isNull);
  });

  testWidgets('switching tab shows past events', (tester) async {
    final followRepo = _FakeFollowRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusPromoterProfileScreen(
          organizer: organizer,
          userId: 'user-1',
          followRepository: followRepo,
          eventsStream: Stream.value([upcomingEvent, pastEvent]),
          now: () => DateTime.utc(2026, 8, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noite Eletrónica'), findsOneWidget);

    await tester.tap(find.text('Anteriores (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Festival de Abertura'), findsOneWidget);
  });
}

final class _FakeFollowRepository implements PromoterFollowRepository {
  _FakeFollowRepository({bool initialFollowing = false})
      : _isFollowing = initialFollowing;

  bool _isFollowing;
  String? lastSetUserId;
  String? lastSetOrganizerId;
  bool? lastSetIsFollowing;

  @override
  Future<void> setFollowing({
    required String userId,
    required String organizerId,
    required bool isFollowing,
  }) async {
    lastSetUserId = userId;
    lastSetOrganizerId = organizerId;
    lastSetIsFollowing = isFollowing;
    _isFollowing = isFollowing;
  }

  @override
  Stream<Set<String>> watchFollowedOrganizerIds(String userId) =>
      Stream.value(_isFollowing ? {'org-1'} : {});

  @override
  Stream<int> watchFollowerCount(String organizerId) => Stream.value(42);

  @override
  Stream<bool> watchIsFollowing({
    required String userId,
    required String organizerId,
  }) =>
      Stream.value(_isFollowing);
}
