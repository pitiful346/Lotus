import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/backend/backend.dart';
import '/custom_code/event_mapping/events_record_to_event.dart';
import '/custom_code/event_mapping/firestore_organizer_repository.dart';
import '/custom_code/event_mapping/firestore_teaser_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/custom_code/widgets/lotus_event_navigation.dart';
import '/index.dart';

/// Centralized deep link router for the Lotus ecosystem.
final class LotusDeepLinkHandler {
  LotusDeepLinkHandler._();

  static final instance = LotusDeepLinkHandler._();

  /// Parses and navigates to the content designated by [rawUri].
  Future<bool> handleUri(BuildContext context, String? rawUri) async {
    if (rawUri == null || rawUri.trim().isEmpty) return false;
    final trimmed = rawUri.trim();

    try {
      final uri = Uri.parse(trimmed);

      // Handle lotus:// custom scheme
      if (uri.scheme == 'lotus') {
        final host = uri.host.toLowerCase();
        final pathSegments = uri.pathSegments;

        if (host == 'event' || host == 'events') {
          final eventId = pathSegments.isNotEmpty ? pathSegments.first : null;
          if (eventId != null && eventId.isNotEmpty) {
            return await _openEventById(context, eventId);
          }
        } else if (host == 'promoter' || host == 'organizer') {
          final promoterId = pathSegments.isNotEmpty ? pathSegments.first : null;
          if (promoterId != null && promoterId.isNotEmpty) {
            return await _openPromoterById(context, promoterId);
          }
        } else if (host == 'teaser' || host == 'radar') {
          final teaserId = pathSegments.isNotEmpty ? pathSegments.first : null;
          if (teaserId != null && teaserId.isNotEmpty) {
            return await _openTeaserById(context, teaserId);
          } else {
            await openLotusRadar(context);
            return true;
          }
        } else if (host == 'saved' || host == 'favorites' || host == 'favoritos') {
          context.pushNamed(FavoritosWidget.routeName);
          return true;
        }
      }

      // Handle path-based routes: /event/123, /promoter/123, /teaser/123
      final path = uri.path.toLowerCase();
      if (path.startsWith('/event/')) {
        final eventId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
        if (eventId != null) return await _openEventById(context, eventId);
      } else if (path.startsWith('/promoter/')) {
        final promoterId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
        if (promoterId != null) return await _openPromoterById(context, promoterId);
      } else if (path.startsWith('/teaser/')) {
        final teaserId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
        if (teaserId != null) return await _openTeaserById(context, teaserId);
      } else if (path == '/radar') {
        await openLotusRadar(context);
        return true;
      } else if (path == '/saved' || path == '/favoritos') {
        context.pushNamed(FavoritosWidget.routeName);
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Extracts deep link metadata from [message] and executes navigation.
  Future<bool> handleRemoteMessage(BuildContext context, RemoteMessage message) async {
    final deepLink = message.data['deep_link'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      final handled = await handleUri(context, deepLink);
      if (handled) return true;
    }

    final rawEventId = message.data['eventId'] as String?;
    if (rawEventId != null && rawEventId.trim().isNotEmpty) {
      return await handleUri(context, 'lotus://event/${rawEventId.trim()}');
    }

    final rawPromoterId = message.data['promoterId'] as String?;
    if (rawPromoterId != null && rawPromoterId.trim().isNotEmpty) {
      return await handleUri(context, 'lotus://promoter/${rawPromoterId.trim()}');
    }

    final rawTeaserId = message.data['teaserId'] as String?;
    if (rawTeaserId != null && rawTeaserId.trim().isNotEmpty) {
      return await handleUri(context, 'lotus://teaser/${rawTeaserId.trim()}');
    }

    if (message.data['route'] == 'saved') {
      return await handleUri(context, 'lotus://saved');
    }

    return false;
  }

  Future<bool> _openEventById(BuildContext context, String eventId) async {
    unawaited(LotusProductFeedback.selection());
    final cleanId = eventId.split('/').last.trim();
    if (cleanId.isEmpty) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('events').doc(cleanId);
      final snapshot = await docRef.get();
      if (!snapshot.exists || !context.mounted) return false;

      final record = EventsRecord.fromSnapshot(snapshot);
      final event = eventFromRecord(record);
      if (event != null && context.mounted) {
        await openLotusEvent(context, event);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _openPromoterById(BuildContext context, String promoterId) async {
    unawaited(LotusProductFeedback.selection());
    final cleanId = promoterId.split('/').last.trim();
    if (cleanId.isEmpty) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('organizers').doc(cleanId);
      final snapshot = await docRef.get();
      if (!snapshot.exists || !context.mounted) return false;

      final organizer = eventOrganizerFromSnapshot(snapshot);
      if (organizer != null && context.mounted) {
        await openLotusPromoterProfile(context, organizer: organizer);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _openTeaserById(BuildContext context, String teaserId) async {
    unawaited(LotusProductFeedback.selection());
    final cleanId = teaserId.split('/').last.trim();
    if (cleanId.isEmpty) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('teasers').doc(cleanId);
      final snapshot = await docRef.get();
      if (!snapshot.exists || !context.mounted) return false;

      final teaser = teaserFromSnapshot(snapshot);
      if (teaser != null && context.mounted) {
        await openLotusTeaserDetails(context, teaser);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
