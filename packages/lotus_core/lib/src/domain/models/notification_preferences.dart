enum EventNotificationKind {
  promoterNewEvent,
  teaserRevealed,
  favoriteChanged,
  favoriteCancelled,
  favoriteStartingSoon,
  recommendationsDigest,
}

/// User-controlled notification choices.
///
/// Quiet hours and a daily cap are enforced again by the server and cannot
/// be relaxed by the client beyond these safe defaults.
final class NotificationPreferences {
  const NotificationPreferences({
    this.followedPromoters = false,
    this.radarReveals = false,
    this.favoriteEventUpdates = false,
    this.upcomingFavoriteEvents = false,
    this.recommendations = false,
    this.marketing = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.maxPerDay = 3,
  }) : assert(quietHoursStart >= 0 && quietHoursStart <= 23),
       assert(quietHoursEnd >= 0 && quietHoursEnd <= 23),
       assert(maxPerDay >= 1 && maxPerDay <= 5);

  final bool followedPromoters;
  final bool radarReveals;
  final bool favoriteEventUpdates;
  final bool upcomingFavoriteEvents;
  final bool recommendations;
  final bool marketing;
  final int quietHoursStart;
  final int quietHoursEnd;
  final int maxPerDay;

  bool get hasAnySubscription =>
      followedPromoters ||
      radarReveals ||
      favoriteEventUpdates ||
      upcomingFavoriteEvents ||
      recommendations ||
      marketing;

  bool allows(EventNotificationKind kind) => switch (kind) {
    EventNotificationKind.promoterNewEvent => followedPromoters,
    EventNotificationKind.teaserRevealed => radarReveals,
    EventNotificationKind.favoriteChanged ||
    EventNotificationKind.favoriteCancelled => favoriteEventUpdates,
    EventNotificationKind.favoriteStartingSoon => upcomingFavoriteEvents,
    EventNotificationKind.recommendationsDigest => recommendations,
  };

  NotificationPreferences copyWith({
    bool? followedPromoters,
    bool? radarReveals,
    bool? favoriteEventUpdates,
    bool? upcomingFavoriteEvents,
    bool? recommendations,
    bool? marketing,
  }) => NotificationPreferences(
    followedPromoters: followedPromoters ?? this.followedPromoters,
    radarReveals: radarReveals ?? this.radarReveals,
    favoriteEventUpdates: favoriteEventUpdates ?? this.favoriteEventUpdates,
    upcomingFavoriteEvents:
        upcomingFavoriteEvents ?? this.upcomingFavoriteEvents,
    recommendations: recommendations ?? this.recommendations,
    marketing: marketing ?? this.marketing,
    quietHoursStart: quietHoursStart,
    quietHoursEnd: quietHoursEnd,
    maxPerDay: maxPerDay,
  );
}
