/// Framework-independent business code for Lotus.
///
/// Public models, repository contracts, and use cases are exported from this
/// library as they are introduced. FlutterFlow-specific types must stay in the
/// application bridge under `lib/custom_code/`.
library;

export 'src/application/use_cases/calculate_event_distance.dart';
export 'src/application/use_cases/filter_events.dart';
export 'src/application/use_cases/load_events_in_viewport.dart';
export 'src/application/use_cases/recommend_events.dart';
export 'src/application/use_cases/parse_natural_event_query.dart';
export 'src/application/use_cases/search_events_naturally.dart';
export 'src/application/use_cases/search_events.dart';
export 'src/domain/models/event.dart';
export 'src/domain/models/event_category.dart';
export 'src/domain/models/event_filters.dart';
export 'src/domain/models/event_interaction_summary.dart';
export 'src/domain/models/event_link.dart';
export 'src/domain/models/event_location.dart';
export 'src/domain/models/event_organizer.dart';
export 'src/domain/models/event_price.dart';
export 'src/domain/models/event_search_result.dart';
export 'src/domain/models/geo_coordinates.dart';
export 'src/domain/models/map_viewport_bounds.dart';
export 'src/domain/models/natural_event_query.dart';
export 'src/domain/models/recommended_event.dart';
export 'src/domain/repositories/map_event_repository.dart';
export 'src/domain/repositories/event_search_repository.dart';
export 'src/domain/repositories/favorite_repository.dart';
export 'src/domain/repositories/personalization_repository.dart';
export 'src/domain/services/natural_event_query_interpreter.dart';
