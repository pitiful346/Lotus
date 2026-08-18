import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_core/lotus_core.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';

const _background = Color(0xFF0A0E13);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

/// Full event presentation kept outside the generated FlutterFlow page.
class EventDetailsContent extends StatelessWidget {
  const EventDetailsContent({
    super.key,
    required this.event,
    required this.isFavorite,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
    this.isUpdatingFavorite = false,
    this.onOpenDirections,
    this.onOpenTickets,
  });

  final Event event;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onOpenDirections;
  final VoidCallback? onOpenTickets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: event.hasTickets
          ? _TicketBar(event: event, onOpenTickets: onOpenTickets)
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 320,
            backgroundColor: _background,
            surfaceTintColor: Colors.transparent,
            leading: _RoundAction(
              tooltip: 'Voltar',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            actions: [
              _RoundAction(
                tooltip: 'Partilhar evento',
                icon: Icons.ios_share_rounded,
                onPressed: onShare,
              ),
              _RoundAction(
                tooltip: isFavorite
                    ? 'Remover dos favoritos'
                    : 'Guardar nos favoritos',
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? _accent : Colors.white,
                onPressed: isUpdatingFavorite ? null : onToggleFavorite,
                showProgress: isUpdatingFavorite,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _EventHero(event: event),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.categories
                            .map((category) => _Pill(label: category.label))
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _EventSchedule(event: event),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Localização',
                        child: _LocationCard(
                          event: event,
                          onOpenDirections: onOpenDirections,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Sobre o evento',
                        child: SelectableText(
                          event.description,
                          style: const TextStyle(
                            color: Color(0xFFD5DCE5),
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Organização',
                        child: _OrganizerCard(organizer: event.organizer),
                      ),
                      const SizedBox(height: 28),
                      _PriceAndAvailability(event: event),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final imageUri = event.imageUri;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUri != null)
          Semantics(
            image: true,
            label: 'Imagem do evento ${event.title}',
            child: CachedNetworkImage(
              imageUrl: imageUri.toString(),
              fit: BoxFit.cover,
              memCacheWidth: 1440,
              fadeInDuration: const Duration(milliseconds: 180),
              placeholder: (context, url) => const _HeroFallback(),
              errorWidget: (context, url, error) => const _HeroFallback(),
            ),
          )
        else
          const _HeroFallback(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3000000), Color(0x12000000), _background],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263241), _background],
        ),
      ),
      child: Center(
        child: Icon(Icons.event_rounded, size: 64, color: Color(0xFF64748B)),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.showProgress = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xB3181F28),
          disabledBackgroundColor: const Color(0x8A181F28),
        ),
        icon: LotusAnimatedSwap(
          child: showProgress
              ? const SizedBox(
                  key: ValueKey('action-progress'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                )
              : Icon(icon, key: ValueKey(icon), color: color),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1FB7F34A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x4DB7F34A)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EventSchedule extends StatelessWidget {
  const _EventSchedule({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = event.startsAt.toLocal();
    final end = event.endsAt?.toLocal();
    final date = localizations.formatFullDate(start);
    final startTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
    );
    final endTime = end == null
        ? null
        : localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end));
    final isSameDay =
        end != null &&
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    return _InfoRow(
      icon: Icons.calendar_month_rounded,
      title: date,
      subtitle: end == null
          ? startTime
          : isSameDay
          ? '$startTime – $endTime'
          : '$startTime – ${localizations.formatMediumDate(end)}, $endTime',
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x1FB7F34A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: _accent, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.event, this.onOpenDirections});

  final Event event;
  final VoidCallback? onOpenDirections;

  @override
  Widget build(BuildContext context) {
    final location = event.location;
    final venue = location.venueName;
    final displayName = location.displayName;
    final showBoth = venue != null && venue != displayName;

    return _SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: _accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue ?? displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showBoth) ...[
                  const SizedBox(height: 3),
                  Text(
                    displayName,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          if (onOpenDirections != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Abrir direções',
              onPressed: onOpenDirections,
              icon: const Icon(Icons.directions_rounded, color: _accent),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.organizer});

  final EventOrganizer? organizer;

  @override
  Widget build(BuildContext context) {
    final value = organizer;
    return _SurfaceCard(
      child: Row(
        children: [
          _OrganizerAvatar(organizer: value),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value?.name ?? 'Organizador não indicado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Organização do evento',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizerAvatar extends StatelessWidget {
  const _OrganizerAvatar({required this.organizer});

  final EventOrganizer? organizer;

  @override
  Widget build(BuildContext context) {
    final imageUri = organizer?.imageUri;
    final initial = organizer?.name.characters.first.toUpperCase() ?? 'L';
    return CircleAvatar(
      radius: 26,
      backgroundColor: const Color(0xFF2B3542),
      backgroundImage: imageUri == null
          ? null
          : CachedNetworkImageProvider(imageUri.toString()),
      child: imageUri == null
          ? Text(
              initial,
              style: const TextStyle(
                color: _accent,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _PriceAndAvailability extends StatelessWidget {
  const _PriceAndAvailability({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.confirmation_number_rounded, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatEventPrice(event.price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ticketAvailabilityLabel(event.ticketAvailability),
                  style: TextStyle(
                    color: _availabilityColor(event.ticketAvailability),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _TicketBar extends StatelessWidget {
  const _TicketBar({required this.event, this.onOpenTickets});

  final Event event;
  final VoidCallback? onOpenTickets;

  @override
  Widget build(BuildContext context) {
    final isUnavailable =
        event.ticketAvailability == TicketAvailability.soldOut ||
        event.ticketAvailability == TicketAvailability.unavailable;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF5151B23),
        border: Border(top: BorderSide(color: _surfaceBorder)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preço',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatEventPrice(event.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              key: const Key('event-ticket-cta'),
              onPressed: isUnavailable ? null : onOpenTickets,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF10150B),
                disabledBackgroundColor: const Color(0xFF47513B),
                disabledForegroundColor: const Color(0xFFB8C1AA),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(_ticketActionLabel(event, isUnavailable)),
            ),
          ],
        ),
      ),
    );
  }
}

String _ticketActionLabel(Event event, bool isUnavailable) {
  if (event.ticketAvailability == TicketAvailability.soldOut) {
    return 'Esgotado';
  }
  if (isUnavailable) {
    return 'Indisponível';
  }
  if (event.ticketAvailability == TicketAvailability.limited) {
    return 'Últimos bilhetes';
  }
  return event.isFree ? 'Reservar' : 'Comprar bilhete';
}

String formatEventPrice(EventPrice price) {
  final minimum = price.minimumMinorUnits;
  if (minimum == null) {
    return 'Preço não indicado';
  }
  if (price.isFree) {
    return 'Grátis';
  }

  final formatter = NumberFormat.currency(
    locale: 'pt_PT',
    name: price.currencyCode,
    symbol: price.currencyCode == 'EUR' ? '€' : price.currencyCode,
  );
  final formattedMinimum = formatter.format(minimum / 100);
  final maximum = price.maximumMinorUnits;
  if (maximum == null || maximum == minimum) {
    return 'Desde $formattedMinimum';
  }
  return '$formattedMinimum – ${formatter.format(maximum / 100)}';
}

String ticketAvailabilityLabel(TicketAvailability availability) {
  return switch (availability) {
    TicketAvailability.available => 'Bilhetes disponíveis',
    TicketAvailability.limited => 'Poucos bilhetes disponíveis',
    TicketAvailability.soldOut => 'Bilhetes esgotados',
    TicketAvailability.unavailable => 'Bilhetes indisponíveis',
    TicketAvailability.unknown => 'Disponibilidade por confirmar',
  };
}

Color _availabilityColor(TicketAvailability availability) {
  return switch (availability) {
    TicketAvailability.available => _accent,
    TicketAvailability.limited => const Color(0xFFFFC857),
    TicketAvailability.soldOut ||
    TicketAvailability.unavailable => const Color(0xFFFF7A7A),
    TicketAvailability.unknown => _muted,
  };
}
