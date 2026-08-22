import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';

/// Centralized analytics coordinator for Lotus Mobile.
class LotusAnalytics {
  LotusAnalytics._();

  static final LotusAnalytics instance = LotusAnalytics._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs an analytics event to Firestore and debug console.
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    final payload = <String, dynamic>{
      'event_name': eventName,
      'user_id': currentUserUid.isNotEmpty ? currentUserUid : 'anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'local_time': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      if (parameters != null) ...parameters,
    };

    if (kDebugMode) {
      debugPrint('📊 [LotusAnalytics] $eventName: $parameters');
    }

    try {
      await _firestore.collection('analytics_events').add(payload);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [LotusAnalytics] Failed to send event $eventName: $e');
      }
    }
  }

  /// Evento visto
  Future<void> logEventViewed({
    required String eventId,
    required String title,
    String? category,
  }) {
    return logEvent('event_viewed', parameters: {
      'event_id': eventId,
      'title': title,
      if (category != null) 'category': category,
    });
  }

  /// Pin no mapa aberto
  Future<void> logPinOpened({
    required String eventId,
    required String title,
  }) {
    return logEvent('pin_opened', parameters: {
      'event_id': eventId,
      'title': title,
    });
  }

  /// Favorito alternado
  Future<void> logFavoriteToggled({
    required String eventId,
    required bool isFavorite,
  }) {
    return logEvent('favorite_toggled', parameters: {
      'event_id': eventId,
      'is_favorite': isFavorite,
    });
  }

  /// Partilha de evento
  Future<void> logEventShared({
    required String eventId,
    required String title,
  }) {
    return logEvent('event_shared', parameters: {
      'event_id': eventId,
      'title': title,
    });
  }

  /// Clique em comprar/reservar bilhetes
  Future<void> logTicketClicked({
    required String eventId,
    required String title,
    required String ticketUrl,
  }) {
    return logEvent('ticket_clicked', parameters: {
      'event_id': eventId,
      'title': title,
      'ticket_url': ticketUrl,
    });
  }

  /// Pesquisa efetuada
  Future<void> logSearch({
    required String query,
    int? resultCount,
  }) {
    return logEvent('search_performed', parameters: {
      'query': query,
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  /// Seguir / Deixar de seguir promoter
  Future<void> logPromoterFollowed({
    required String organizerId,
    required bool isFollowing,
  }) {
    return logEvent('promoter_followed', parameters: {
      'organizer_id': organizerId,
      'is_following': isFollowing,
    });
  }

  /// Teaser / Radar acompanhado
  Future<void> logTeaserTracked({
    required String teaserId,
    required String title,
  }) {
    return logEvent('teaser_tracked', parameters: {
      'teaser_id': teaserId,
      'title': title,
    });
  }
}
