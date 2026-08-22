import 'dart:async';

import '/backend/backend.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/event_details/event_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/firestore_event_search_repository.dart';
import 'lotus_search_history.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _accent = Color(0xFFB7F34A);

/// Bounded conventional and structured natural-language event search.
class LotusEventSearch extends StatefulWidget {
  const LotusEventSearch({
    super.key,
    this.repository,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.onOpenEvent,
    this.interpreter,
    this.now,
    this.historyStore,
  });

  final EventSearchRepository? repository;
  final Duration debounceDuration;
  final ValueChanged<Event>? onOpenEvent;
  final NaturalEventQueryInterpreter? interpreter;
  final DateTime Function()? now;
  final LotusSearchHistoryStore? historyStore;

  @override
  State<LotusEventSearch> createState() => _LotusEventSearchState();
}

class _LotusEventSearchState extends State<LotusEventSearch> {
  static const _corpusLimit = 200;

  late EventSearchRepository _repository;
  late NaturalEventQueryInterpreter _interpreter;
  late LotusSearchHistoryStore _historyStore;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Event>? _corpus;
  List<EventSearchResult> _results = const [];
  NaturalEventQuery? _interpretation;
  bool _isLoading = false;
  bool _hasError = false;
  int _searchVersion = 0;
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreEventSearchRepository();
    _interpreter = widget.interpreter ?? const ParseNaturalEventQuery();
    _historyStore =
        widget.historyStore ?? SharedPreferencesLotusSearchHistoryStore();
    unawaited(_loadHistory());
  }

  @override
  void didUpdateWidget(LotusEventSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? FirestoreEventSearchRepository();
      _corpus = null;
      _results = const [];
      _searchVersion += 1;
    }
    if (oldWidget.interpreter != widget.interpreter) {
      _interpreter = widget.interpreter ?? const ParseNaturalEventQuery();
      _interpretation = null;
    }
    if (oldWidget.historyStore != widget.historyStore) {
      _historyStore =
          widget.historyStore ?? SharedPreferencesLotusSearchHistoryStore();
      unawaited(_loadHistory());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _queryChanged(String value) {
    _debounce?.cancel();
    _searchVersion += 1;
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _isLoading = false;
        _hasError = false;
        _interpretation = null;
      });
      return;
    }
    _debounce = Timer(widget.debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    final version = ++_searchVersion;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _results = const [];
      _interpretation = null;
    });
    try {
      final corpus =
          _corpus ?? await _repository.loadCorpus(limit: _corpusLimit);
      if (!mounted || version != _searchVersion) {
        return;
      }
      _corpus = corpus;
      final interpretation = _interpreter.interpret(
        query,
        now: widget.now?.call() ?? DateTime.now(),
      );
      setState(() {
        _interpretation = interpretation.requiresStructuredSearch
            ? interpretation
            : null;
        _results = interpretation.requiresStructuredSearch
            ? const SearchEventsNaturally()(corpus, interpretation)
                  .map(
                    (event) => EventSearchResult(
                      type: EventSearchResultType.event,
                      key: event.id,
                      title: event.title,
                      events: [event],
                    ),
                  )
                  .toList(growable: false)
            : SearchEvents()(corpus, query);
        _isLoading = false;
      });
      unawaited(_remember(query));
    } catch (_) {
      if (!mounted || version != _searchVersion) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _results = const [];
        _interpretation = null;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _historyStore.load();
      if (!mounted) return;
      setState(() => _history = history.take(8).toList(growable: false));
    } catch (_) {
      // Search remains usable when local preferences are unavailable.
    }
  }

  Future<void> _remember(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final updated = <String>[
      normalized,
      ..._history.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(8).toList(growable: false);
    if (mounted) setState(() => _history = updated);
    try {
      await _historyStore.save(updated);
    } catch (_) {
      // Search results must not depend on local history persistence.
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _history = const []);
    try {
      await _historyStore.save(const []);
    } catch (_) {
      // The in-memory history is already cleared for this session.
    }
  }

  void _applySuggestion(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    setState(() {});
    unawaited(_search(query));
  }

  void _clear() {
    unawaited(LotusProductFeedback.selection());
    _searchVersion += 1;
    _controller.clear();
    _queryChanged('');
    _focusNode.requestFocus();
  }

  Future<void> _openEvent(Event event) async {
    unawaited(LotusProductFeedback.selection());
    final callback = widget.onOpenEvent;
    if (callback != null) {
      callback(event);
      return;
    }
    try {
      final reference = FirebaseFirestore.instance.doc(event.id);
      final record = await EventsRecord.getDocumentOnce(reference);
      if (!mounted) {
        return;
      }
      context.pushNamed(
        EventDetailsWidget.routeName,
        queryParameters: {
          'eventoAtual': serializeParam(record, ParamType.Document),
        }.withoutNulls,
        extra: <String, dynamic>{'eventoAtual': record},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir os detalhes do evento.'),
          ),
        );
      }
    }
  }

  Future<void> _openFacet(EventSearchResult result) {
    unawaited(LotusProductFeedback.selection());
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                result.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: result.events.length,
                itemBuilder: (context, index) {
                  final event = result.events[index];
                  return _EventRow(
                    event: event,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openEvent(event);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pesquisa'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: TextField(
                key: const Key('event-search-field'),
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: (value) {
                  setState(() {});
                  _queryChanged(value);
                },
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex.: techno amanhã à noite no Porto',
                  hintStyle: const TextStyle(color: Color(0xFF8795A6)),
                  prefixIcon: const Icon(Icons.search_rounded, color: _accent),
                  suffixIcon: hasQuery
                      ? IconButton(
                          key: const Key('clear-event-search'),
                          onPressed: _clear,
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF293342)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF293342)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
            ),
            if (_interpretation case final interpretation?)
              _StructuredQueryChips(query: interpretation),
            Expanded(
              child: LotusAnimatedSwap(
                child: KeyedSubtree(
                  key: ValueKey((
                    _isLoading,
                    _hasError,
                    hasQuery,
                    _results.length,
                  )),
                  child: _body(hasQuery),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool hasQuery) {
    if (!hasQuery) {
      return _SearchIntroduction(
        history: _history,
        onSelect: _applySuggestion,
        onClearHistory: _history.isEmpty ? null : _clearHistory,
      );
    }
    if (_isLoading) {
      return const LotusSkeletonList(itemCount: 5, compact: true);
    }
    if (_hasError) {
      return LotusStateView(
        kind: LotusStateKind.offline,
        title: 'Pesquisa indisponível',
        message:
            'Verifica a ligação. Os conteúdos já guardados continuam disponíveis noutras áreas.',
        actionLabel: 'Tentar novamente',
        onAction: () => _search(_controller.text.trim()),
      );
    }
    if (_results.isEmpty) {
      return const LotusStateView(
        kind: LotusStateKind.empty,
        icon: Icons.search_off_rounded,
        title: 'Sem resultados',
        message: 'Experimenta outro nome, local, artista ou categoria.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        for (final type in EventSearchResultType.values)
          if (_results.any((result) => result.type == type)) ...[
            _ResultSectionTitle(type),
            for (final result in _results.where((item) => item.type == type))
              result.type == EventSearchResultType.event
                  ? _EventRow(
                      event: result.event!,
                      onTap: () => _openEvent(result.event!),
                    )
                  : _FacetRow(result: result, onTap: () => _openFacet(result)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _SearchIntroduction extends StatelessWidget {
  const _SearchIntroduction({
    required this.history,
    required this.onSelect,
    required this.onClearHistory,
  });

  final List<String> history;
  final ValueChanged<String> onSelect;
  final VoidCallback? onClearHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      children: [
        const Column(
          children: [
            Icon(Icons.travel_explore_rounded, color: _accent, size: 44),
            SizedBox(height: 16),
            Text(
              'Descobre o que está a acontecer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pesquisa por evento, local, artista, organizador ou categoria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            SizedBox(height: 6),
            Text(
              'Também podes escrever: “quero techno amanhã à noite no Porto”.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Sugestões',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final query in const [
              'Hoje',
              'Este fim de semana',
              'Música no Porto',
              'Eventos gratuitos',
            ])
              ActionChip(
                label: Text(
                  query,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF293342)),
                ),
                onPressed: () => onSelect(query),
              ),
          ],
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pesquisas recentes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const Key('clear-search-history'),
                onPressed: onClearHistory,
                child: const Text('Limpar'),
              ),
            ],
          ),
          for (final query in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_rounded,
                color: Color(0xFF94A3B8),
              ),
              title: Text(
                query,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.north_west_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              onTap: () => onSelect(query),
            ),
        ],
      ],
    );
  }
}

class _StructuredQueryChips extends StatelessWidget {
  const _StructuredQueryChips({required this.query});

  final NaturalEventQuery query;

  @override
  Widget build(BuildContext context) {
    final labels = <String>{
      if (query.dateStart != null) _dateLabel(query),
      if (query.dayPeriod != null) _periodLabel(query.dayPeriod!),
      ...query.locationTerms.map(_displayToken),
      ...query.categoryIds.map(_categoryLabel),
      ...query.keywordTokens.map(_displayToken),
      if (query.freeOnly) 'Gratuitos',
      if (query.maximumPriceMinorUnits case final price?)
        'Até ${(price / 100).round()} €',
    }.toList(growable: false);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF223020),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF47652D)),
          ),
          child: Text(
            labels[index],
            style: const TextStyle(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _dateLabel(NaturalEventQuery query) {
  final normalized = canonicalFilterValue(query.originalText);
  if (normalized.contains('depois-de-amanha')) {
    return 'Depois de amanhã';
  }
  if (normalized.contains('amanha')) {
    return 'Amanhã';
  }
  if (normalized.contains('hoje')) {
    return 'Hoje';
  }
  if (normalized.contains('fim-de-semana')) {
    return 'Fim de semana';
  }
  return 'Data escolhida';
}

String _periodLabel(EventDayPeriod period) => switch (period) {
  EventDayPeriod.earlyMorning => 'Madrugada',
  EventDayPeriod.morning => 'Manhã',
  EventDayPeriod.afternoon => 'Tarde',
  EventDayPeriod.night => 'Noite',
};

String _categoryLabel(String value) => switch (value) {
  'musica' => 'Música',
  'festas' => 'Festas',
  'cultura' => 'Cultura',
  'desporto' => 'Desporto',
  _ => _displayToken(value),
};

String _displayToken(String value) {
  final words = value.split('-').where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _ResultSectionTitle extends StatelessWidget {
  const _ResultSectionTitle(this.type);

  final EventSearchResultType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      EventSearchResultType.event => 'Eventos',
      EventSearchResultType.venue => 'Locais',
      EventSearchResultType.artist => 'Artistas e organizadores',
      EventSearchResultType.category => 'Categorias',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFAFBCCB),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUri = event.imageUri;
    return Semantics(
      button: true,
      label:
          '${event.title}, ${event.location.displayName}, ${_shortDate(event.startsAt)}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          color: _surface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF293342)),
          ),
          child: ListTile(
            onTap: onTap,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imageUri == null
                    ? const ColoredBox(
                        color: Color(0xFF25303C),
                        child: Icon(Icons.event_rounded, color: _accent),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUri.toString(),
                        fit: BoxFit.cover,
                        memCacheWidth: 156,
                        memCacheHeight: 156,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (_, __) =>
                            const ColoredBox(color: Color(0xFF25303C)),
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: Color(0xFF25303C),
                          child: Icon(Icons.event_rounded, color: _accent),
                        ),
                      ),
              ),
            ),
            title: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${event.location.displayName} · ${_shortDate(event.startsAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class _FacetRow extends StatelessWidget {
  const _FacetRow({required this.result, required this.onTap});

  final EventSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (result.type) {
      EventSearchResultType.venue => Icons.place_outlined,
      EventSearchResultType.artist => Icons.mic_none_rounded,
      EventSearchResultType.category => Icons.category_outlined,
      EventSearchResultType.event => Icons.event_outlined,
    };
    final count = result.events.length;
    return Semantics(
      button: true,
      label: '${result.title}, ${count == 1 ? '1 evento' : '$count eventos'}',
      onTap: onTap,
      child: Card(
        color: _surface,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF293342)),
        ),
        child: ExcludeSemantics(
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF25303C),
              foregroundColor: _accent,
              child: Icon(icon),
            ),
            title: Text(
              result.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              count == 1 ? '1 evento' : '$count eventos',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)} · '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
