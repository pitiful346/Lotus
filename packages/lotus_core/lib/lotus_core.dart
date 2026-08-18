/// Framework-independent business code for Lotus.
///
/// Public models, repository contracts, and use cases are exported from this
/// library as they are introduced. FlutterFlow-specific types must stay in the
/// application bridge under `lib/custom_code/`.
library;

export 'src/domain/models/event.dart';
export 'src/domain/models/event_category.dart';
export 'src/domain/models/event_link.dart';
export 'src/domain/models/event_location.dart';
export 'src/domain/models/event_organizer.dart';
export 'src/domain/models/event_price.dart';
export 'src/domain/models/geo_coordinates.dart';
