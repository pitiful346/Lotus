import '../models/natural_event_query.dart';

/// Boundary that can later be implemented by an LLM or semantic service.
abstract interface class NaturalEventQueryInterpreter {
  NaturalEventQuery interpret(String text, {required DateTime now});
}
