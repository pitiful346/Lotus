import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/events_record_to_event.dart';
import '/custom_code/widgets/event_details_content.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

export 'event_details_model.dart';

/// FlutterFlow route wrapper for the maintainable event details UI.
class EventDetailsWidget extends StatefulWidget {
  const EventDetailsWidget({super.key, required this.eventoAtual});

  final EventsRecord? eventoAtual;

  static String routeName = 'EventDetails';
  static String routePath = '/eventDetails';

  @override
  State<EventDetailsWidget> createState() => _EventDetailsWidgetState();
}

class _EventDetailsWidgetState extends State<EventDetailsWidget> {
  bool _isUpdatingFavorite = false;

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
        return StreamBuilder<UsersRecord>(
          stream: UsersRecord.getDocument(organizerReference),
          builder: (context, organizerSnapshot) {
            final organizer = organizerSnapshot.hasData
                ? eventOrganizerFromRecord(organizerSnapshot.data!)
                : null;
            return _buildDetails(record, organizer);
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
        final isFavorite =
            currentUserDocument?.favoritos.contains(record.reference) ?? false;
        return EventDetailsContent(
          event: event,
          isFavorite: isFavorite,
          isUpdatingFavorite: _isUpdatingFavorite,
          onBack: context.safePop,
          onShare: () => _shareEvent(event),
          onToggleFavorite: () => _toggleFavorite(record.reference),
          onOpenDirections: event.location.coordinates == null
              ? null
              : () => _openDirections(event),
          onOpenTickets: event.hasTickets ? () => _openTickets(event) : null,
        );
      },
    );
  }

  Future<void> _toggleFavorite(DocumentReference eventReference) async {
    if (_isUpdatingFavorite) {
      return;
    }
    final userReference = currentUserReference;
    if (userReference == null) {
      _showMessage('Inicia sessão para guardares eventos nos favoritos.');
      return;
    }

    final isFavorite =
        currentUserDocument?.favoritos.contains(eventReference) ?? false;
    setState(() => _isUpdatingFavorite = true);
    try {
      await userReference.update({
        'favoritos': isFavorite
            ? FieldValue.arrayRemove([eventReference])
            : FieldValue.arrayUnion([eventReference]),
      });
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
