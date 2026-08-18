import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_core/lotus_core.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';

const lotusSurface = Color(0xFF151B23);
const lotusBorder = Color(0xFF293342);

class LotusEventPosterCard extends StatelessWidget {
  const LotusEventPosterCard({
    super.key,
    required this.event,
    required this.onTap,
    this.badge,
  });

  final Event event;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${event.title}, ${_eventDate(event)}, ${event.location.displayName}',
    onTap: onTap,
    child: ExcludeSemantics(
      child: SizedBox(
        width: 230,
        child: Card(
          color: lotusSurface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: lotusBorder),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _EventImage(event: event),
                      if (badge case final value?)
                        Positioned(left: 10, top: 10, child: _Badge(value)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _eventDate(event),
                        style: const TextStyle(
                          color: lotusQualityAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.location.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: lotusQualityMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LotusEventListTile extends StatelessWidget {
  const LotusEventListTile({
    super.key,
    required this.event,
    required this.onTap,
    this.trailing,
  });

  final Event event;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    color: lotusSurface,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: lotusBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Semantics(
      button: true,
      label:
          '${event.title}, ${_eventDate(event)}, ${event.location.displayName}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: ListTile(
          onTap: onTap,
          minVerticalPadding: 10,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.square(
              dimension: 62,
              child: _EventImage(event: event),
            ),
          ),
          title: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${_eventDate(event)}\n${event.location.displayName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: lotusQualityMuted, height: 1.35),
          ),
          trailing: trailing,
        ),
      ),
    ),
  );
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final image = event.imageUri;
    if (image == null) {
      return const ColoredBox(
        color: Color(0xFF25303C),
        child: Icon(Icons.event_rounded, color: lotusQualityAccent),
      );
    }
    return CachedNetworkImage(
      imageUrl: image.toString(),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF25303C)),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Color(0xFF25303C),
        child: Icon(Icons.event_rounded, color: lotusQualityMuted),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6080C11),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

String _eventDate(Event event) =>
    DateFormat('EEE, d MMM · HH:mm').format(event.startsAt.toLocal());
