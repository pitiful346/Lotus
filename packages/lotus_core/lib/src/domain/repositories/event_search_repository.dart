import '../models/event.dart';

/// Supplies a bounded corpus to the initial conventional search engine.
abstract interface class EventSearchRepository {
  Future<List<Event>> loadCorpus({required int limit});
}
