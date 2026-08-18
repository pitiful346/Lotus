import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

const _accent = Color(0xFFB7F34A);
const _surface = Color(0xFF151B23);

class EventFilterSheet extends StatefulWidget {
  const EventFilterSheet({
    super.key,
    required this.initialFilters,
    required this.hasUserLocation,
  });

  final EventFilters initialFilters;
  final bool hasUserLocation;

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  static const _categories = {
    'musica': 'Música',
    'festas': 'Festas',
    'cultura': 'Cultura',
    'desporto': 'Desporto',
  };
  static const _distances = [
    (2000.0, '2 km'),
    (5000.0, '5 km'),
    (10000.0, '10 km'),
    (25000.0, '25 km'),
    (50000.0, '50 km'),
  ];
  static const _prices = {
    1000: 'Até 10 €',
    2000: 'Até 20 €',
    5000: 'Até 50 €',
    10000: 'Até 100 €',
  };

  late EventDateFilter? _date;
  late Set<String> _categoriesSelected;
  late bool _freeOnly;
  late double? _maximumDistanceMeters;
  late int? _maximumPriceMinorUnits;

  @override
  void initState() {
    super.initState();
    _load(widget.initialFilters);
  }

  void _load(EventFilters filters) {
    _date = filters.date;
    _categoriesSelected = {...filters.categoryIds};
    _freeOnly = filters.freeOnly;
    _maximumDistanceMeters = widget.hasUserLocation
        ? filters.maximumDistanceMeters
        : null;
    _maximumPriceMinorUnits = filters.maximumPriceMinorUnits;
  }

  EventFilters get _filters => EventFilters(
    date: _date,
    categoryIds: _categoriesSelected,
    freeOnly: _freeOnly,
    maximumDistanceMeters: _maximumDistanceMeters,
    maximumPriceMinorUnits: _maximumPriceMinorUnits,
  );

  void _clear() {
    setState(() => _load(EventFilters()));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _DragHandle()),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('clear-event-filters'),
                    onPressed: _filters.isEmpty ? null : _clear,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Quando'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dateChip(EventDateFilter.today, 'Hoje'),
                  _dateChip(EventDateFilter.tomorrow, 'Amanhã'),
                  _dateChip(EventDateFilter.thisWeekend, 'Este fim de semana'),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Categorias'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _categories.entries)
                    FilterChip(
                      label: Text(category.value),
                      selected: _categoriesSelected.contains(category.key),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _categoriesSelected.add(category.key);
                          } else {
                            _categoriesSelected.remove(category.key);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SwitchListTile.adaptive(
                key: const Key('free-events-filter'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Gratuitos',
                  style: TextStyle(color: Colors.white),
                ),
                value: _freeOnly,
                activeThumbColor: _accent,
                onChanged: (value) => setState(() => _freeOnly = value),
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Distância máxima'),
              if (!widget.hasUserLocation)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Ativa a localização para filtrar por distância.',
                    style: TextStyle(color: Color(0xFF9AA8B8)),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final distance in _distances)
                    ChoiceChip(
                      label: Text(distance.$2),
                      selected: _maximumDistanceMeters == distance.$1,
                      onSelected: widget.hasUserLocation
                          ? (selected) => setState(
                              () => _maximumDistanceMeters = selected
                                  ? distance.$1
                                  : null,
                            )
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Preço máximo'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final price in _prices.entries)
                    ChoiceChip(
                      label: Text(price.value),
                      selected: _maximumPriceMinorUnits == price.key,
                      onSelected: (selected) => setState(
                        () => _maximumPriceMinorUnits = selected
                            ? price.key
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('apply-event-filters'),
                  onPressed: () => Navigator.pop(context, _filters),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF11161D),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Aplicar filtros',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(EventDateFilter value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _date == value,
      onSelected: (selected) => setState(() => _date = selected ? value : null),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFDCE4EE),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 42,
      child: Divider(thickness: 4, color: Color(0xFF4B5868)),
    );
  }
}
