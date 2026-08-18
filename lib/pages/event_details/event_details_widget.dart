import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/events_record_to_event.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/custom_code/event_mapping/firestore_organizer_repository.dart';
import '/custom_code/widgets/event_details_content.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

export 'event_details_model.dart';

/// FlutterFlow route wrapper for the maintainable event details UI.
class EventDetailsWidget extends StatefulWidget {
  const EventDetailsWidget({
    super.key,
    required this.eventoAtual,
    this.favoriteRepository,
  });

  final EventsRecord? eventoAtual;
  final FavoriteRepository? favoriteRepository;

  static String routeName = 'EventDetails';
  static String routePath = '/eventDetails';

  @override
  State<EventDetailsWidget> createState() => _EventDetailsWidgetState();
}

class _EventDetailsWidgetState extends State<EventDetailsWidget> {
  bool _isUpdatingFavorite = false;
  late final FavoriteRepository _favoriteRepository;

  @override
  void initState() {
    super.initState();
    _favoriteRepository =
        widget.favoriteRepository ?? FirestoreFavoriteRepository();
  }

  @override
  Widget build(BuildContext context) {
    final initialRecord = widget.eventoAtual;
    if (initialRecord == null) {
      return _EventDetailsUnavailable(onBack: context.safePop);
    }

    return StreamBuilder<EventsRecord>(
      stream: EventsRecord.getDocument(initialRecord.reference),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EventDetailsUnavailable(onBack: context.safePop);
        }
        final record = snapshot.data;
        if (record == null) {
          return const _EventDetailsLoading();
        }

        final organizerReference = record.organizerId;
        if (organizerReference == null) {
          return _buildDetails(record, null);
        }
        return StreamBuilder<EventOrganizer?>(
          stream: watchEventOrganizer(organizerReference),
          builder: (context, organizerSnapshot) {
            return _buildDetails(record, organizerSnapshot.data);
          },
        );
      },
    );
  }

  Widget _buildDetails(EventsRecord record, EventOrganizer? organizer) {
    final event = eventFromRecord(record, organizer: organizer);
    if (event == null) {
      return _EventDetailsUnavailable(onBack: context.safePop);
    }

    return AuthUserStreamWidget(
      builder: (context) {
        final userId = currentUserUid;
        final favoriteStream = userId.isEmpty
            ? Stream<bool>.value(false)
            : _favoriteRepository.watchIsFavorite(
                userId: userId,
                eventId: record.reference.path,
              );
        return StreamBuilder<bool>(
          stream: favoriteStream,
          initialData:
              currentUserDocument?.favoritos.contains(record.reference) ??
              false,
          builder: (context, favoriteSnapshot) {
            final isFavorite = favoriteSnapshot.data ?? false;
            return EventDetailsContent(
              event: event,
              isFavorite: isFavorite,
              isUpdatingFavorite: _isUpdatingFavorite,
              onBack: context.safePop,
              onShare: () => _shareEvent(event),
              onToggleFavorite: () => _toggleFavorite(
                eventId: record.reference.path,
                isFavorite: isFavorite,
              ),
              onOpenDirections: event.location.coordinates == null
                  ? null
                  : () => _openDirections(event),
              onOpenTickets: event.hasTickets
                  ? () => _openTickets(event)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFavorite({
    required String eventId,
    required bool isFavorite,
  }) async {
    if (_isUpdatingFavorite) {
      return;
    }
    final userId = currentUserUid;
    if (userId.isEmpty) {
      _showMessage('Inicia sessão para guardares eventos nos favoritos.');
      return;
    }

    setState(() => _isUpdatingFavorite = true);
    try {
      await _favoriteRepository.setFavorite(
        userId: userId,
        eventId: eventId,
        isFavorite: !isFavorite,
      );
    } catch (_) {
      _showMessage('Não foi possível atualizar os favoritos.');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFavorite = false);
      }
    }
  }

  Future<void> _shareEvent(Event event) async {
    final localStart = event.startsAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatFullDate(localStart);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localStart),
    );
    final ticketUri = _ticketUri(event);
    final message = [
      event.title,
      '$date · $time',
      event.location.displayName,
      if (ticketUri != null) ticketUri.toString(),
    ].join('\n');
    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    try {
      await Share.share(
        message,
        subject: event.title,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      _showMessage('Não foi possível partilhar este evento.');
    }
  }

  Future<void> _openDirections(Event event) async {
    final coordinates = event.location.coordinates;
    if (coordinates == null) {
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${coordinates.latitude},${coordinates.longitude}',
    });
    await _launchExternal(uri, 'Não foi possível abrir as direções.');
  }

  Future<void> _openTickets(Event event) async {
    final uri = _ticketUri(event);
    if (uri == null) {
      return;
    }
    await _launchExternal(uri, 'Não foi possível abrir a bilheteira.');
  }

  Future<void> _launchExternal(Uri uri, String failureMessage) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showMessage(failureMessage);
      }
    } catch (_) {
      _showMessage(failureMessage);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

Uri? _ticketUri(Event event) {
  for (final link in event.links) {
    if (link.kind == EventLinkKind.tickets) {
      return link.uri;
    }
  }
  return null;
}

class _EventDetailsLoading extends StatelessWidget {
  const _EventDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E13),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFB7F34A))),
    );
  }
}

class _EventDetailsUnavailable extends StatelessWidget {
  const _EventDetailsUnavailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E13),
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este evento já não está disponível.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
        ),
      ),
    );
  }
}
