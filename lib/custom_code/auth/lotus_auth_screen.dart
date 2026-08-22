import 'dart:async';

import 'package:flutter/material.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  minHeight: constraints.maxHeight - 100,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: registering
                          ? _buildRegistration(theme)
                          : _buildLogin(theme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin(FlutterFlowTheme theme) => Column(
    key: const Key('auth-login-view'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(
          'Lotus',
          style: theme.headlineLarge.copyWith(
            color: theme.primaryText,
            height: 1.1,
          ),
        ),
      ),
      const SizedBox(height: 48),
      Text(
        'Qual é o teu email?',
        style: theme.bodyMedium.copyWith(height: 1.4),
      ),
      const SizedBox(height: 24),
      _authField(
        key: const Key('auth-email'),
        controller: _emailController,
        label: 'Email',
        autofillHints: const [AutofillHints.email],
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
      ),
      const SizedBox(height: 16),
      _passwordField(registering: false),
      _errorView(theme),
      const SizedBox(height: 24),
      _loginSubmitButton(theme),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.center,
        child: InkWell(
          onTap: _submitting ? null : () => unawaited(_resetPassword()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Recuperar palavra-passe',
              style: theme.bodyMedium.copyWith(color: theme.primary),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _divider(theme),
      const SizedBox(height: 24),
      _modePrompt(
        theme: theme,
        message: 'Ainda não tens conta?',
        action: 'Criar conta',
        key: const Key('show-register'),
        onTap: () => _setMode(LotusAuthMode.register),
      ),
      const Spacer(),
      const SizedBox(height: 32),
      Text(
        'Ao continuar, concordas com os Termos e a Política de Privacidade do Lotus.',
        textAlign: TextAlign.center,
        style: theme.bodySmall.copyWith(
          color: theme.secondaryText,
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _buildRegistration(FlutterFlowTheme theme) => Column(
    key: const Key('auth-register-view'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Como te chamas?',
        style: theme.headlineMedium.copyWith(
          color: theme.primaryText,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Cria a tua conta para descobrires o que acontece à tua volta.',
        style: theme.bodyLarge.copyWith(
          color: theme.secondaryText,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 48),
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: Column(
            children: [
              _authField(
                key: const Key('auth-name'),
                controller: _nameController,
                label: 'Nome',
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Indica o teu nome.'
                    : null,
              ),
              const SizedBox(height: 24),
              _authField(
                key: const Key('auth-email'),
                controller: _emailController,
                label: 'Email',
                autofillHints: const [AutofillHints.email],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              _passwordField(registering: true),
            ],
          ),
        ),
      ),
      _errorView(theme),
      const Spacer(),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: theme.secondaryBackground,
            shape: CircleBorder(side: BorderSide(color: theme.alternate)),
            child: IconButton(
              key: const Key('show-login'),
              tooltip: 'Voltar ao login',
              onPressed: _submitting
                  ? null
                  : () => _setMode(LotusAuthMode.login),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          _registrationSubmitButton(theme),
        ],
      ),
    ],
  );

  Widget _authField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: theme.alternate),
      borderRadius: BorderRadius.circular(8),
    );
    return TextFormField(
      key: key,
      controller: controller,
      enabled: !_submitting,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autocorrect: false,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: theme.labelMedium.copyWith(color: theme.secondaryText),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFFB7F34A), width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: theme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: theme.error, width: 1.5),
        ),
        filled: true,
        fillColor: theme.secondaryBackground,
      ),
      style: theme.bodyMedium.copyWith(color: Colors.white),
      cursorColor: const Color(0xFFB7F34A),
      validator: validator,
    );
  }

  Widget _passwordField({required bool registering}) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: theme.alternate),
      borderRadius: BorderRadius.circular(8),
    );
    return TextFormField(
      key: const Key('auth-password'),
      controller: _passwordController,
      enabled: !_submitting,
      autofillHints: registering
          ? const [AutofillHints.newPassword]
          : const [AutofillHints.password],
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => unawaited(_submit()),
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Palavra-passe',
        labelStyle: theme.labelMedium.copyWith(color: theme.secondaryText),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFFB7F34A), width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: theme.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: theme.error, width: 1.5),
        ),
        filled: true,
        fillColor: theme.secondaryBackground,
        suffixIcon: IconButton(
          tooltip: _obscurePassword
              ? 'Mostrar palavra-passe'
              : 'Ocultar palavra-passe',
          onPressed: _submitting
              ? null
              : () => setState(() {
                  _obscurePassword = !_obscurePassword;
                }),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
      style: theme.bodyMedium.copyWith(color: Colors.white),
      cursorColor: const Color(0xFFB7F34A),
      validator: (value) =>
          (value?.length ?? 0) < 6 ? 'Usa pelo menos 6 caracteres.' : null,
    );
  }

  Widget _errorView(FlutterFlowTheme theme) {
    final error = _error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          error,
          key: const Key('auth-error'),
          style: theme.bodySmall.copyWith(
            color: theme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _loginSubmitButton(FlutterFlowTheme theme) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('auth-submit'),
      onTap: _submitting ? null : () => unawaited(_submit()),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _submitting ? 0.65 : 1,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFB7F34A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF11161D),
                  ),
                )
              : const Text(
                  'Entrar',
                  style: TextStyle(
                    color: Color(0xFF11161D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
        ),
      ),
    ),
  );

  Widget _registrationSubmitButton(FlutterFlowTheme theme) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('auth-submit'),
      onTap: _submitting ? null : () => unawaited(_submit()),
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _submitting ? 0.65 : 1,
        child: Container(
          constraints: const BoxConstraints(minWidth: 160, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFB7F34A),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: _submitting
              ? const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF11161D),
                    ),
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Criar conta',
                      style: TextStyle(
                        color: Color(0xFF11161D),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF11161D),
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _divider(FlutterFlowTheme theme) => Row(
    children: [
      Expanded(child: Divider(color: theme.alternate, height: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'ou',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            height: 1.4,
          ),
        ),
      ),
      Expanded(child: Divider(color: theme.alternate, height: 1)),
    ],
  );

  Widget _modePrompt({
    required FlutterFlowTheme theme,
    required String message,
    required String action,
    required Key key,
    required VoidCallback onTap,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        message,
        style: theme.bodySmall.copyWith(
          color: theme.secondaryText,
          height: 1.4,
        ),
      ),
      const SizedBox(width: 8),
      InkWell(
        key: key,
        onTap: _submitting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            action,
            style: theme.bodyMedium.copyWith(
              color: const Color(0xFFB7F34A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  void _setMode(LotusAuthMode mode) {
    if (_submitting || _mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
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
