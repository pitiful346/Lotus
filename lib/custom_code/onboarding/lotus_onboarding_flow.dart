import 'dart:async';

import 'package:flutter/material.dart';

import '/custom_code/location/user_location_controller.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_onboarding_repository.dart';

const _categories = <String, String>{
  'musica': 'Música',
  'festas': 'Festas',
  'cultura': 'Cultura',
  'desporto': 'Desporto',
  'teatro': 'Teatro',
  'comedia': 'Comédia',
};

const _cities = ['Porto', 'Lisboa', 'Braga', 'Coimbra', 'Aveiro'];

class LotusOnboardingFlow extends StatefulWidget {
  const LotusOnboardingFlow({
    super.key,
    required this.userId,
    required this.repository,
    required this.onFinished,
    this.locationController,
  });

  final String userId;
  final LotusOnboardingRepository repository;
  final VoidCallback onFinished;
  final UserLocationController? locationController;

  @override
  State<LotusOnboardingFlow> createState() => _LotusOnboardingFlowState();
}

class _LotusOnboardingFlowState extends State<LotusOnboardingFlow> {
  late final UserLocationController _locationController;
  late final bool _ownsLocationController;
  final Set<String> _interestIds = {};
  int _step = 0;
  String _city = 'Porto';
  UserLocationStatus _locationStatus = UserLocationStatus.idle;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsLocationController = widget.locationController == null;
    _locationController = widget.locationController ?? UserLocationController();
  }

  @override
  void dispose() {
    if (_ownsLocationController) _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C11),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Passo ${_step + 1} de 4',
                          child: LinearProgressIndicator(
                            value: (_step + 1) / 4,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(99),
                            color: lotusQualityAccent,
                            backgroundColor: const Color(0xFF25303C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        key: const Key('onboarding-skip'),
                        onPressed: _saving ? null : _skip,
                        child: const Text('Saltar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: LotusAnimatedSwap(
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _stepContent(),
                      ),
                    ),
                  ),
                  if (_error case final error?) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: const TextStyle(color: Color(0xFFFF8A80)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _step -= 1),
                              child: const Text('Voltar'),
                            ),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            key: const Key('onboarding-next'),
                            onPressed: _saving ? null : _next,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_step == 3 ? 'Concluir' : 'Continuar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() => switch (_step) {
    0 => const _IntroStep(),
    1 => _LocationStep(
      status: _locationStatus,
      onRequest: _requestLocation,
      onOpenSettings: _locationController.openRelevantSettings,
    ),
    2 => _InterestsStep(
      selected: _interestIds,
      onChanged: (id, selected) => setState(() {
        selected ? _interestIds.add(id) : _interestIds.remove(id);
      }),
    ),
    _ => _CityStep(
      city: _city,
      onChanged: (city) => setState(() => _city = city),
    ),
  };

  Future<void> _requestLocation() async {
    final status = await _locationController.refresh(requestPermission: true);
    if (!mounted) return;
    setState(() => _locationStatus = status);
  }

  void _next() {
    if (_step < 3) {
      unawaited(LotusProductFeedback.selection());
      setState(() {
        _step += 1;
        _error = null;
      });
      return;
    }
    unawaited(_finish(skipped: false));
  }

  Future<void> _skip() => _finish(skipped: true);

  Future<void> _finish({required bool skipped}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.complete(
        widget.userId,
        LotusOnboardingSelection(
          city: _city,
          interestIds: skipped ? const {} : _interestIds,
          locationPermissionStatus: skipped ? 'skipped' : _locationStatus.name,
          skipped: skipped,
        ),
      );
      unawaited(LotusProductFeedback.success());
      if (mounted) setState(() => _saving = false);
      widget.onFinished();
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Não foi possível guardar. Verifica a ligação e tenta novamente.';
        });
      }
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep();

  @override
  Widget build(BuildContext context) => const _StepLayout(
    icon: Icons.explore_outlined,
    title: 'A cidade acontece aqui',
    description:
        'Descobre eventos no mapa, guarda os teus favoritos e recebe sugestões relevantes sem perder tempo.',
  );
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final UserLocationStatus status;
  final Future<void> Function() onRequest;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      UserLocationStatus.available => 'Localização pronta.',
      UserLocationStatus.permissionDenied =>
        'Permissão recusada. Podes continuar e ativá-la mais tarde.',
      UserLocationStatus.permissionDeniedForever =>
        'A permissão está bloqueada nas definições do sistema.',
      UserLocationStatus.serviceDisabled =>
        'Os serviços de localização estão desligados.',
      UserLocationStatus.unavailable =>
        'Não foi possível obter a localização agora.',
      _ => 'Usamos a localização apenas para mostrar eventos perto de ti.',
    };
    final needsSettings =
        status == UserLocationStatus.permissionDeniedForever ||
        status == UserLocationStatus.serviceDisabled;
    return _StepLayout(
      icon: Icons.near_me_outlined,
      title: 'Eventos perto de ti',
      description: message,
      child: SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          key: const Key('onboarding-location'),
          onPressed: status == UserLocationStatus.loading
              ? null
              : needsSettings
              ? onOpenSettings
              : onRequest,
          icon: const Icon(Icons.my_location_rounded),
          label: Text(
            needsSettings ? 'Abrir definições' : 'Permitir localização',
          ),
        ),
      ),
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({required this.selected, required this.onChanged});

  final Set<String> selected;
  final void Function(String id, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => _StepLayout(
    icon: Icons.auto_awesome_outlined,
    title: 'O que te interessa?',
    description:
        'Escolhe algumas categorias. Podes alterar esta seleção mais tarde.',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.entries
          .map(
            (entry) {
              final active = selected.contains(entry.key);
              return FilterChip(
                label: Text(
                  entry.value,
                  style: TextStyle(
                    color: active ? const Color(0xFF11161D) : Colors.white,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                selected: active,
                selectedColor: lotusQualityAccent,
                backgroundColor: const Color(0xFF151B23),
                checkmarkColor: const Color(0xFF11161D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: active
                        ? lotusQualityAccent
                        : const Color(0xFF293342),
                  ),
                ),
                onSelected: (value) => onChanged(entry.key, value),
              );
            },
          )
          .toList(),
    ),
  );
}

class _CityStep extends StatelessWidget {
  const _CityStep({required this.city, required this.onChanged});

  final String city;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _StepLayout(
    icon: Icons.location_city_outlined,
    title: 'Qual é a tua cidade inicial?',
    description: 'O mapa começa aqui. Podes explorar qualquer outra área.',
    child: DropdownButtonFormField<String>(
      key: const Key('onboarding-city'),
      initialValue: city,
      dropdownColor: const Color(0xFF151B23),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconEnabledColor: lotusQualityAccent,
      decoration: InputDecoration(
        labelText: 'Cidade',
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF151B23),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF293342)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF293342)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lotusQualityAccent, width: 1.5),
        ),
      ),
      items: _cities
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.icon,
    required this.title,
    required this.description,
    this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 58, color: lotusQualityAccent),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            color: lotusQualityMuted,
            fontSize: 17,
            height: 1.45,
          ),
        ),
        if (child != null) ...[const SizedBox(height: 28), child!],
      ],
    ),
  );
}
