enum EventNotificationKind {
  favoriteChanged,
  favoriteStartingSoon,
  recommendationsDigest,
}

/// User-controlled notification choices.
///
/// All content switches default to off so that receiving notifications is an
/// explicit choice. Quiet hours and a daily cap are enforced again by the
/// server and cannot be relaxed by the client beyond these safe defaults.
final class NotificationPreferences {
  const NotificationPreferences({
    this.favoriteEventUpdates = false,
    this.upcomingFavoriteEvents = false,
    this.recommendations = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.maxPerDay = 3,
  }) : assert(quietHoursStart >= 0 && quietHoursStart <= 23),
       assert(quietHoursEnd >= 0 && quietHoursEnd <= 23),
       assert(maxPerDay >= 1 && maxPerDay <= 3);

  final bool favoriteEventUpdates;
  final bool upcomingFavoriteEvents;
  final bool recommendations;
  final int quietHoursStart;
  final int quietHoursEnd;
  final int maxPerDay;

  bool get hasAnySubscription =>
      favoriteEventUpdates || upcomingFavoriteEvents || recommendations;

  bool allows(EventNotificationKind kind) => switch (kind) {
    EventNotificationKind.favoriteChanged => favoriteEventUpdates,
    EventNotificationKind.favoriteStartingSoon => upcomingFavoriteEvents,
    EventNotificationKind.recommendationsDigest => recommendations,
  };

  NotificationPreferences copyWith({
    bool? favoriteEventUpdates,
    bool? upcomingFavoriteEvents,
    bool? recommendations,
  }) => NotificationPreferences(
    favoriteEventUpdates: favoriteEventUpdates ?? this.favoriteEventUpdates,
    upcomingFavoriteEvents:
        upcomingFavoriteEvents ?? this.upcomingFavoriteEvents,
    recommendations: recommendations ?? this.recommendations,
    quietHoursStart: quietHoursStart,
    quietHoursEnd: quietHoursEnd,
    maxPerDay: maxPerDay,
  );
}
