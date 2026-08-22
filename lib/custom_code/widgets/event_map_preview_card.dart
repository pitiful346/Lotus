import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_core/lotus_core.dart';

class EventMapPreviewCard extends StatelessWidget {
  const EventMapPreviewCard({
    super.key,
    required this.event,
    required this.onClose,
    required this.onOpenDetails,
    this.distanceMeters,
    this.isOpening = false,
    this.isFavorite = false,
    this.isUpdatingFavorite = false,
    this.onToggleFavorite,
    this.bottomInset = 16,
  });

  final Event event;
  final double? distanceMeters;
  final bool isOpening;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final double bottomInset;
  final VoidCallback onClose;
  final VoidCallback onOpenDetails;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final localStart = event.startsAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(localStart);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localStart),
    );
    final category = event.categories.first.label;
    final additionalCategories = event.categories.length - 1;
    final venue = event.location.venueName ?? event.location.displayName;
    final distanceAndPrice = [
      formatEventDistance(distanceMeters),
      formatEventPreviewPrice(event.price),
    ].join(' · ');

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: const Color(0xF21B2029),
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x33FFFFFF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 126,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EventPreviewImage(imageUri: event.imageUri),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      tooltip: isFavorite
                                          ? 'Remover dos favoritos'
                                          : 'Guardar nos favoritos',
                                      padding: EdgeInsets.zero,
                                      onPressed: isUpdatingFavorite
                                          ? null
                                          : onToggleFavorite,
                                      icon: isUpdatingFavorite
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFB7F34A),
                                              ),
                                            )
                                          : Icon(
                                              isFavorite
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                        .favorite_border_rounded,
                                              size: 20,
                                              color: isFavorite
                                                  ? const Color(0xFFB7F34A)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      tooltip: 'Fechar',
                                      padding: EdgeInsets.zero,
                                      onPressed: onClose,
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _PreviewMetadata(
                                icon: Icons.calendar_today_outlined,
                                label: '$date · $time',
                              ),
                              const SizedBox(height: 6),
                              _PreviewMetadata(
                                icon: Icons.location_on_outlined,
                                label: venue,
                              ),
                              const SizedBox(height: 6),
                              _PreviewMetadata(
                                icon: Icons.near_me_outlined,
                                label: distanceAndPrice,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0x1FB7F34A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                additionalCategories > 0
                                    ? '$category +$additionalCategories'
                                    : category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB7F34A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: isOpening ? null : onOpenDetails,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: const Color(0xFFB7F34A),
                          foregroundColor: const Color(0xFF11161D),
                          disabledBackgroundColor: const Color(0xFF65753E),
                          minimumSize: const Size(0, 36),
                        ),
                        icon: isOpening
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF11161D),
                                ),
                              )
                            : const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Ver evento'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPreviewImage extends StatelessWidget {
  const _EventPreviewImage({required this.imageUri});

  final Uri? imageUri;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 104,
        child: imageUri == null
            ? const _ImageFallback()
            : CachedNetworkImage(
                imageUrl: imageUri.toString(),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) =>
                    const _ImageFallback(showLoader: true),
                errorWidget: (context, url, error) => const _ImageFallback(),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.showLoader = false});

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B3440), Color(0xFF11161D)],
        ),
      ),
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB7F34A),
                ),
              )
            : const Icon(
                Icons.image_outlined,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
      ),
    );
  }
}

class _PreviewMetadata extends StatelessWidget {
  const _PreviewMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

String formatEventDistance(double? distanceMeters) {
  if (distanceMeters == null ||
      !distanceMeters.isFinite ||
      distanceMeters < 0) {
    return 'Distância indisponível';
  }
  if (distanceMeters < 1000) {
    return '${distanceMeters.round()} m de distância';
  }
  final kilometers = (distanceMeters / 1000).toStringAsFixed(1);
  return '${kilometers.replaceAll('.', ',')} km de distância';
}

String formatEventPreviewPrice(EventPrice price) {
  final minimum = price.minimumMinorUnits;
  if (minimum == null) return 'Preço não indicado';
  if (price.isFree) return 'Grátis';

  final formatter = NumberFormat.currency(
    locale: 'pt_PT',
    name: price.currencyCode,
    symbol: price.currencyCode == 'EUR' ? '€' : price.currencyCode,
    decimalDigits: minimum % 100 == 0 ? 0 : 2,
  );
  final formattedMinimum = formatter.format(minimum / 100);
  final maximum = price.maximumMinorUnits;
  if (maximum == null || maximum == minimum) {
    return 'Desde $formattedMinimum';
  }
  return '$formattedMinimum–${formatter.format(maximum / 100)}';
}
