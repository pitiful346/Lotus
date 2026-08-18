import 'dart:async';

import 'package:flutter/material.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_auth_service.dart';

enum LotusAuthMode { login, register }

class LotusAuthScreen extends StatefulWidget {
  const LotusAuthScreen({super.key, this.service});

  final LotusAuthService? service;

  @override
  State<LotusAuthScreen> createState() => _LotusAuthScreenState();
}

class _LotusAuthScreenState extends State<LotusAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LotusAuthService _service;
  LotusAuthMode _mode = LotusAuthMode.login;
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FirebaseLotusAuthService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registering = _mode == LotusAuthMode.register;
    return Scaffold(
      backgroundColor: const Color(0xFF080C11),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'LOTUS',
                          style: TextStyle(
                            color: lotusQualityAccent,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        registering
                            ? 'Cria a tua conta e começa a descobrir a cidade.'
                            : 'Entra para guardares eventos e receberes recomendações.',
                        style: const TextStyle(
                          color: lotusQualityMuted,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<LotusAuthMode>(
                        segments: const [
                          ButtonSegment(
                            value: LotusAuthMode.login,
                            label: Text('Entrar'),
                          ),
                          ButtonSegment(
                            value: LotusAuthMode.register,
                            label: Text('Criar conta'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: _submitting
                            ? null
                            : (selection) => setState(() {
                                _mode = selection.single;
                                _error = null;
                              }),
                      ),
                      const SizedBox(height: 24),
                      LotusAnimatedSwap(
                        child: registering
                            ? Padding(
                                key: const ValueKey('registration-name'),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  key: const Key('auth-name'),
                                  controller: _nameController,
                                  enabled: !_submitting,
                                  autofillHints: const [AutofillHints.name],
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      registering &&
                                          (value?.trim().length ?? 0) < 2
                                      ? 'Indica o teu nome.'
                                      : null,
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('no-registration-name'),
                              ),
                      ),
                      TextFormField(
                        key: const Key('auth-email'),
                        controller: _emailController,
                        enabled: !_submitting,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('auth-password'),
                        controller: _passwordController,
                        enabled: !_submitting,
                        autofillHints: registering
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Palavra-passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar palavra-passe'
                                : 'Ocultar palavra-passe',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) < 6
                            ? 'Usa pelo menos 6 caracteres.'
                            : null,
                      ),
                      if (_error case final error?) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            key: const Key('auth-error'),
                            style: const TextStyle(color: Color(0xFFFF8A80)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const Key('auth-submit'),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(registering ? 'Criar conta' : 'Entrar'),
                        ),
                      ),
                      if (!registering)
                        TextButton(
                          onPressed: _submitting ? null : _resetPassword,
                          child: const Text('Recuperar palavra-passe'),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'O login social poderá ser adicionado mais tarde sem alterar este fluxo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: lotusQualityMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Indica um email válido.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_mode == LotusAuthMode.register) {
        await _service.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _service.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      unawaited(LotusProductFeedback.success());
    } on LotusAuthFailure catch (error) {
      unawaited(LotusProductFeedback.error());
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        setState(() => _error = 'Não foi possível concluir a autenticação.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviámos as instruções de recuperação por email.'),
        ),
      );
    } on LotusAuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
