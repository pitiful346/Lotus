import '../../domain/models/event_filters.dart';
import '../../domain/models/natural_event_query.dart';
import '../../domain/services/natural_event_query_interpreter.dart';

/// Portuguese baseline interpreter for common event-search phrases.
final class ParseNaturalEventQuery implements NaturalEventQueryInterpreter {
  const ParseNaturalEventQuery();

  static const _stopWords = {
    'a',
    'ao',
    'as',
    'com',
    'da',
    'das',
    'de',
    'do',
    'dos',
    'e',
    'em',
    'encontrar',
    'esta',
    'este',
    'evento',
    'eventos',
    'ha',
    'na',
    'nas',
    'no',
    'nos',
    'nesta',
    'neste',
    'o',
    'os',
    'para',
    'perto',
    'procuro',
    'quero',
    'ver',
  };

  static const _knownLocations = {
    'porto',
    'matosinhos',
    'gaia',
    'vila-nova-de-gaia',
    'maia',
    'braga',
    'lisboa',
    'aveiro',
  };

  static const _categoryAliases = <String, ({String category, bool specific})>{
    'musica': (category: 'musica', specific: false),
    'concerto': (category: 'musica', specific: true),
    'concertos': (category: 'musica', specific: true),
    'techno': (category: 'musica', specific: true),
    'house': (category: 'musica', specific: true),
    'jazz': (category: 'musica', specific: true),
    'rock': (category: 'musica', specific: true),
    'hip-hop': (category: 'musica', specific: true),
    'festas': (category: 'festas', specific: false),
    'festa': (category: 'festas', specific: false),
    'clubbing': (category: 'festas', specific: true),
    'nightlife': (category: 'festas', specific: true),
    'cultura': (category: 'cultura', specific: false),
    'teatro': (category: 'cultura', specific: true),
    'cinema': (category: 'cultura', specific: true),
    'arte': (category: 'cultura', specific: true),
    'exposicao': (category: 'cultura', specific: true),
    'exposicoes': (category: 'cultura', specific: true),
    'desporto': (category: 'desporto', specific: false),
    'futebol': (category: 'desporto', specific: true),
    'corrida': (category: 'desporto', specific: true),
    'running': (category: 'desporto', specific: true),
  };

  @override
  NaturalEventQuery interpret(String text, {required DateTime now}) {
    final normalized = canonicalFilterValue(text);
    if (normalized.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Must not be blank.');
    }
    final tokens = normalized.split('-');
    final consumed = <int>{};
    final categories = <String>{};
    final locations = <String>{};
    final keywords = <String>{};
    DateTime? dateStart;
    DateTime? dateEnd;
    EventDayPeriod? dayPeriod;
    var freeOnly = false;
    int? maximumPrice;

    final today = _startOfDay(now);
    final afterTomorrow = _phraseIndex(tokens, const [
      'depois',
      'de',
      'amanha',
    ]);
    if (afterTomorrow != null) {
      consumed.addAll([afterTomorrow, afterTomorrow + 1, afterTomorrow + 2]);
      dateStart = _addDays(today, 2);
      dateEnd = _addDays(today, 3);
    } else if (tokens.contains('amanha')) {
      final index = tokens.indexOf('amanha');
      consumed.add(index);
      dateStart = _addDays(today, 1);
      dateEnd = _addDays(today, 2);
    } else if (tokens.contains('hoje')) {
      final index = tokens.indexOf('hoje');
      consumed.add(index);
      dateStart = today;
      dateEnd = _addDays(today, 1);
    } else {
      final weekend = _phraseIndex(tokens, const ['fim', 'de', 'semana']);
      if (weekend != null) {
        consumed.addAll([weekend, weekend + 1, weekend + 2]);
        final daysUntilSaturday = today.weekday == DateTime.sunday
            ? -1
            : (DateTime.saturday - today.weekday + 7) % 7;
        dateStart = _addDays(today, daysUntilSaturday);
        dateEnd = _addDays(dateStart, 2);
      }
    }

    const periods = {
      'madrugada': EventDayPeriod.earlyMorning,
      'manha': EventDayPeriod.morning,
      'tarde': EventDayPeriod.afternoon,
      'noite': EventDayPeriod.night,
    };
    for (final entry in periods.entries) {
      final index = tokens.indexOf(entry.key);
      if (index >= 0) {
        consumed.add(index);
        dayPeriod = entry.value;
        break;
      }
    }

    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      final hasLocationCue =
          tokens.length > 1 &&
          ((index > 0 &&
                  const {'em', 'no', 'na'}.contains(tokens[index - 1])) ||
              (index > 1 &&
                  tokens[index - 2] == 'perto' &&
                  tokens[index - 1] == 'de') ||
              tokens.length > 2);
      if (_knownLocations.contains(token) && hasLocationCue) {
        locations.add(token);
        consumed.add(index);
      }
      final alias = _categoryAliases[token];
      if (alias != null) {
        categories.add(alias.category);
        if (!alias.specific) {
          consumed.add(index);
        }
      }
      if (const {
        'gratis',
        'gratuito',
        'gratuita',
        'gratuitos',
        'gratuitas',
      }.contains(token)) {
        freeOnly = true;
        consumed.add(index);
      }
    }

    final entranceFree = _phraseIndex(tokens, const ['entrada', 'livre']);
    if (entranceFree != null) {
      freeOnly = true;
      consumed.addAll([entranceFree, entranceFree + 1]);
    }

    for (var index = 0; index < tokens.length - 1; index += 1) {
      final startsPrice =
          tokens[index] == 'ate' ||
          (tokens[index] == 'menos' &&
              index + 2 < tokens.length &&
              tokens[index + 1] == 'de');
      final numberIndex = tokens[index] == 'ate' ? index + 1 : index + 2;
      if (!startsPrice || numberIndex >= tokens.length) {
        continue;
      }
      final euros = int.tryParse(tokens[numberIndex]);
      if (euros != null && euros >= 0) {
        maximumPrice = euros * 100;
        consumed.addAll(
          List.generate(numberIndex - index + 1, (offset) => index + offset),
        );
        if (numberIndex + 1 < tokens.length &&
            const {'euro', 'euros'}.contains(tokens[numberIndex + 1])) {
          consumed.add(numberIndex + 1);
        }
        break;
      }
    }

    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      if (!consumed.contains(index) && !_stopWords.contains(token)) {
        keywords.add(token);
      }
    }

    return NaturalEventQuery(
      originalText: text,
      keywordTokens: keywords,
      categoryIds: categories,
      locationTerms: locations,
      dateStart: dateStart,
      dateEndExclusive: dateEnd,
      dayPeriod: dayPeriod,
      freeOnly: freeOnly,
      maximumPriceMinorUnits: maximumPrice,
    );
  }
}

int? _phraseIndex(List<String> tokens, List<String> phrase) {
  for (var index = 0; index <= tokens.length - phrase.length; index += 1) {
    var matches = true;
    for (var offset = 0; offset < phrase.length; offset += 1) {
      if (tokens[index + offset] != phrase[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return index;
    }
  }
  return null;
}

DateTime _startOfDay(DateTime value) => value.isUtc
    ? DateTime.utc(value.year, value.month, value.day)
    : DateTime(value.year, value.month, value.day);

DateTime _addDays(DateTime value, int days) => value.isUtc
    ? DateTime.utc(value.year, value.month, value.day + days)
    : DateTime(value.year, value.month, value.day + days);
