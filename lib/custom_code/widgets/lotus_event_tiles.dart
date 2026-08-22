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

class LotusFeaturedEventHeroCard extends StatelessWidget {
  const LotusFeaturedEventHeroCard({
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
            'Evento em destaque: ${event.title}, ${_eventDate(event)}, ${event.location.displayName}',
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            width: 320,
            child: Card(
              color: lotusSurface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: const Color(0xFFB7F34A).withValues(alpha: 0.4),
                  width: 1.3,
                ),
              ),
              elevation: 4,
              shadowColor: const Color(0x66000000),
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 175,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _EventImage(event: event),
                          // Subtle dark gradient for high legibility
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.transparent,
                                    lotusSurface.withValues(alpha: 0.95),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _FeaturedCuratedBadge(
                              label: badge ?? 'CURADORIA LOTUS',
                            ),
                          ),
                          if (event.isFree)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: _PriceBadge(label: 'ENTRADA LIVRE'),
                            )
                          else if (event.price.minimumMinorUnits case final minUnits?)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: _PriceBadge(
                                label: 'Desde ${(minUnits / 100).toStringAsFixed(0)}€',
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: lotusQualityAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _eventDate(event),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: lotusQualityAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: lotusQualityMuted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event.location.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: lotusQualityMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (event.organizer != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x26FFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        event.organizer!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFD3DCE6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (event.organizer!.isVerified) ...[
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 11,
                                          color: lotusQualityAccent,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (event.status == EventStatus.cancelled) ...[
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x33FF5252),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Cancelado',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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

class _FeaturedCuratedBadge extends StatelessWidget {
  const _FeaturedCuratedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xE60D1219),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFB7F34A).withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7F34A).withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFB7F34A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB7F34A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xE6080C11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

String _eventDate(Event event) =>
    DateFormat('EEE, d MMM · HH:mm').format(event.startsAt.toLocal());

