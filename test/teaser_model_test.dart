import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  group('Teaser model & status tests', () {
    final organizer = EventOrganizer(
      id: 'organizers/org-1',
      name: 'Lotus Collective',
      isVerified: true,
    );

    final category = EventCategory(id: 'musica', label: 'Música Eletrónica');

    test('creates teaser with full mystery fields and default published status', () {
      final revealTime = DateTime.utc(2026, 10, 1, 20, 0);
      final teaser = Teaser(
        id: 'teasers/secret-1',
        title: 'Projeto Eclipse',
        description: 'Um encontro sonoro exclusivo nas margens do Rio Douro.',
        imageUri: Uri.parse('https://images.lotus.pt/teasers/eclipse.jpg'),
        organizer: organizer,
        category: category,
        city: 'Porto',
        approximateDate: 'Outono 2026',
        revealAt: revealTime,
        trackerCount: 57,
      );

      expect(teaser.id, 'teasers/secret-1');
      expect(teaser.title, 'Projeto Eclipse');
      expect(teaser.displayTitle, 'Projeto Eclipse');
      expect(teaser.city, 'Porto');
      expect(teaser.approximateDate, 'Outono 2026');
      expect(teaser.status, TeaserStatus.published);
      expect(teaser.trackerCount, 57);
      expect(teaser.targetEventId, isNull);
    });

    test('displayTitle falls back gracefully when title is null or blank', () {
      final revealTime = DateTime.utc(2026, 10, 1);
      final teaserCategory = Teaser(
        id: 'teasers/1',
        description: 'Enigma',
        category: category,
        revealAt: revealTime,
      );
      expect(teaserCategory.displayTitle, 'Evento Secreto de Música Eletrónica');

      final teaserCity = Teaser(
        id: 'teasers/2',
        description: 'Enigma',
        city: 'Lisboa',
        revealAt: revealTime,
      );
      expect(teaserCity.displayTitle, 'Evento Secreto em Lisboa');

      final teaserAnonymous = Teaser(
        id: 'teasers/3',
        description: 'Enigma',
        revealAt: revealTime,
      );
      expect(teaserAnonymous.displayTitle, 'Evento Secreto');
    });

    test('status lifecycle transitions and string conversions', () {
      expect(TeaserStatus.fromString('PUBLISHED'), TeaserStatus.published);
      expect(TeaserStatus.fromString('TEASER_ACTIVE'), TeaserStatus.published);
      expect(TeaserStatus.fromString('ACTIVE'), TeaserStatus.published);
      expect(TeaserStatus.fromString('REVEALED'), TeaserStatus.revealed);
      expect(TeaserStatus.fromString('EXPIRED'), TeaserStatus.expired);
      expect(TeaserStatus.fromString('CANCELLED'), TeaserStatus.cancelled);
      expect(TeaserStatus.fromString('draft'), TeaserStatus.draft);
      expect(TeaserStatus.fromString('UNKNOWN'), TeaserStatus.draft);

      expect(TeaserStatus.published.wireName, 'PUBLISHED');
      expect(TeaserStatus.revealed.wireName, 'REVEALED');
      expect(TeaserStatus.expired.wireName, 'EXPIRED');
      expect(TeaserStatus.cancelled.wireName, 'CANCELLED');
    });

    test('isActive and isRevealed correctly evaluate according to revealAt time', () {
      final futureReveal = DateTime.utc(2026, 12, 31);
      final activeTeaser = Teaser(
        id: 'teasers/active',
        description: 'Em breve',
        revealAt: futureReveal,
        status: TeaserStatus.published,
      );

      final nowBefore = DateTime.utc(2026, 10, 1);
      expect(activeTeaser.timeUntilReveal(nowBefore).inDays, greaterThan(0));

      final pastReveal = DateTime.utc(2026, 1, 1);
      final expiredTeaser = Teaser(
        id: 'teasers/expired',
        description: 'Passado',
        revealAt: pastReveal,
        status: TeaserStatus.published,
      );
      expect(expiredTeaser.timeUntilReveal(nowBefore), Duration.zero);

      final explicitlyRevealed = Teaser(
        id: 'teasers/revealed',
        description: 'Revelado',
        revealAt: futureReveal,
        status: TeaserStatus.revealed,
        targetEventId: 'events/event-99',
      );
      expect(explicitlyRevealed.isRevealed, isTrue);
      expect(explicitlyRevealed.targetEventId, 'events/event-99');
    });
  });
}
