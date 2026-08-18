import 'dart:async';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/event_details/event_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/firestore_event_search_repository.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _accent = Color(0xFFB7F34A);

/// Conventional, bounded search for events and their main facets.
class LotusEventSearch extends StatefulWidget {
  const LotusEventSearch({
    super.key,
    this.repository,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.onOpenEvent,
  });

  final EventSearchRepository? repository;
  final Duration debounceDuration;
  final ValueChanged<Event>? onOpenEvent;

  @override
  State<LotusEventSearch> createState() => _LotusEventSearchState();
}

class _LotusEventSearchState extends State<LotusEventSearch> {
  static const _corpusLimit = 200;

  late EventSearchRepository _repository;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Event>? _corpus;
  List<EventSearchResult> _results = const [];
  bool _isLoading = false;
  bool _hasError = false;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreEventSearchRepository();
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
    });
    try {
      final corpus =
          _corpus ?? await _repository.loadCorpus(limit: _corpusLimit);
      if (!mounted || version != _searchVersion) {
        return;
      }
      _corpus = corpus;
      setState(() {
        _results = SearchEvents()(corpus, query);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _results = const [];
      });
    }
  }

  void _clear() {
    _searchVersion += 1;
    _controller.clear();
    _queryChanged('');
    _focusNode.requestFocus();
  }

  Future<void> _openEvent(Event event) async {
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
                  hintText: 'Eventos, locais, artistas ou categorias',
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
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: _accent,
                backgroundColor: Colors.transparent,
              ),
            Expanded(child: _body(hasQuery)),
          ],
        ),
      ),
    );
  }

  Widget _body(bool hasQuery) {
    if (!hasQuery) {
      return const _SearchIntroduction();
    }
    if (_hasError) {
      return _SearchMessage(
        icon: Icons.cloud_off_outlined,
        message: 'Não foi possível carregar a pesquisa.',
        actionLabel: 'Tentar novamente',
        onAction: () => _search(_controller.text.trim()),
      );
    }
    if (!_isLoading && _results.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_off_rounded,
        message: 'Sem resultados para esta pesquisa.',
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
  const _SearchIntroduction();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Pesquisa por evento, local, artista ou categoria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9AA8B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSectionTitle extends StatelessWidget {
  const _ResultSectionTitle(this.type);

  final EventSearchResultType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      EventSearchResultType.event => 'Eventos',
      EventSearchResultType.venue => 'Locais',
      EventSearchResultType.artist => 'Artistas',
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
    return Card(
      color: _surface,
      margin: const EdgeInsets.only(bottom: 8),
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
                : Image.network(
                    imageUri.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
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
          style: const TextStyle(color: Color(0xFF9AA8B8)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white54,
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
    return Card(
      color: _surface,
      margin: const EdgeInsets.only(bottom: 8),
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
          style: const TextStyle(color: Color(0xFF9AA8B8)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7F8D9E), size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAFBCCB)),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
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
