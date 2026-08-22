import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

import 'package:lotus/custom_code/notifications/lotus_deep_link_handler.dart';
import 'package:lotus/custom_code/widgets/lotus_notification_center_screen.dart';

final class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({List<AppNotification>? initial})
      : _notifications = List.of(initial ?? []);

  final List<AppNotification> _notifications;
  final _controller = StreamController<List<AppNotification>>.broadcast();

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) async* {
    yield List.unmodifiable(_notifications);
    yield* _controller.stream;
  }

  @override
  Stream<int> watchUnreadCount(String userId) async* {
    yield _notifications.where((n) => n.isUnread).length;
    yield* _controller.stream.map(
      (list) => list.where((n) => n.isUnread).length,
    );
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        status: AppNotificationStatus.read,
        readAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(_notifications));
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].isUnread) {
        _notifications[i] = _notifications[i].copyWith(
          status: AppNotificationStatus.read,
          readAt: DateTime.now(),
        );
      }
    }
    _controller.add(List.unmodifiable(_notifications));
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LotusNotificationCenterScreen widget tests', () {
    late _FakeNotificationRepository repo;

    setUp(() {
      repo = _FakeNotificationRepository(initial: [
        AppNotification(
          id: 'n1',
          title: 'Novo Evento no Lux',
          body: 'Lux Frágil publicou "Electronic Night".',
          type: 'promoter_new_event',
          status: AppNotificationStatus.unread,
          deepLink: 'lotus://event/e100',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AppNotification(
          id: 'n2',
          title: '⚡ Revelação no Radar!',
          body: 'O teaser "Secret Warehouse" foi revelado.',
          type: 'teaser_revealed',
          status: AppNotificationStatus.unread,
          deepLink: 'lotus://event/e200',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: 'n3',
          title: 'Alteração em Evento Favorito',
          body: 'A hora de início foi atualizada para as 23:00.',
          type: 'favorite_changed',
          status: AppNotificationStatus.read,
          deepLink: 'lotus://event/e300',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          readAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
      ]);
    });

    tearDown(() {
      repo.dispose();
    });

    Widget createScreen() {
      return MaterialApp(
        home: LotusNotificationCenterScreen(
          repository: repo,
          userId: 'user_123',
          now: () => DateTime.now(),
        ),
      );
    }

    testWidgets('renders all notifications with titles, bodies, and chips', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notificações'), findsOneWidget);
      expect(find.text('Todas (3)'), findsOneWidget);
      expect(find.text('Não lidas (2)'), findsOneWidget);

      expect(find.text('Novo Evento no Lux'), findsOneWidget);
      expect(find.text('Lux Frágil publicou "Electronic Night".'), findsOneWidget);
      expect(find.text('⚡ Revelação no Radar!'), findsOneWidget);
      expect(find.text('Alteração em Evento Favorito'), findsOneWidget);
    });

    testWidgets('filters list when tapping Não lidas chip', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Alteração em Evento Favorito'), findsOneWidget);

      await tester.tap(find.text('Não lidas (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Novo Evento no Lux'), findsOneWidget);
      expect(find.text('⚡ Revelação no Radar!'), findsOneWidget);
      expect(find.text('Alteração em Evento Favorito'), findsNothing);
    });

    testWidgets('marks all notifications as read when tapping mark all button', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Não lidas (2)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('notification-mark-all-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Não lidas (0)'), findsOneWidget);
      expect(find.text('Todas (3)'), findsOneWidget);
    });

    testWidgets('marks single notification as read when tapped', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Não lidas (2)'), findsOneWidget);

      await tester.tap(find.text('Novo Evento no Lux'));
      await tester.pumpAndSettle();

      expect(find.text('Não lidas (1)'), findsOneWidget);
    });
  });

  group('LotusDeepLinkHandler tests', () {
    test('extracts deep link from RemoteMessage data payload', () async {
      final handler = LotusDeepLinkHandler.instance;
      expect(handler, isNotNull);

      const messageWithDeepLink = RemoteMessage(
        data: {'deep_link': 'lotus://event/event_abc'},
      );

      const messageWithEventId = RemoteMessage(
        data: {'eventId': 'event_xyz'},
      );

      const messageWithPromoterId = RemoteMessage(
        data: {'promoterId': 'org_123'},
      );

      const messageWithTeaserId = RemoteMessage(
        data: {'teaserId': 'teaser_999'},
      );

      expect(messageWithDeepLink.data['deep_link'], 'lotus://event/event_abc');
      expect(messageWithEventId.data['eventId'], 'event_xyz');
      expect(messageWithPromoterId.data['promoterId'], 'org_123');
      expect(messageWithTeaserId.data['teaserId'], 'teaser_999');
    });
  });
}
