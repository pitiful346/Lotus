import 'dart:async';

import 'package:flutter/material.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_auth_service.dart';

class LotusAccountActions extends StatefulWidget {
  const LotusAccountActions({super.key, this.service});

  final LotusAuthService? service;

  @override
  State<LotusAccountActions> createState() => _LotusAccountActionsState();
}

class _LotusAccountActionsState extends State<LotusAccountActions> {
  late final LotusAuthService _service;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FirebaseLotusAuthService();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          key: const Key('account-sign-out'),
          onPressed: _signingOut ? null : _confirmSignOut,
          icon: _signingOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout_rounded),
          label: const Text('Terminar sessão'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        key: const Key('account-delete'),
        onPressed: _signingOut ? null : _confirmDeleteAccount,
        icon: const Icon(Icons.delete_forever_outlined),
        label: const Text('Eliminar conta'),
        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
      ),
    ],
  );

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminar sessão?'),
        content: const Text(
          'Os dados guardados nesta conta continuarão disponíveis quando voltares a entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminar sessão'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await _service.signOut();
      unawaited(LotusProductFeedback.success());
      if (mounted) {
        setState(() => _signingOut = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível terminar a sessão.')),
        );
        setState(() => _signingOut = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    var enteredPassword = '';
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta ação é permanente. A conta, favoritos, preferências e imagens associadas serão eliminados.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('delete-account-password'),
              obscureText: true,
              onChanged: (value) => enteredPassword = value,
              decoration: const InputDecoration(
                labelText: 'Confirma a palavra-passe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-delete-account'),
            onPressed: () => Navigator.pop(dialogContext, enteredPassword),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await _service.deleteAccount(password: password);
      unawaited(LotusProductFeedback.success());
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on LotusAuthFailure catch (error) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível eliminar a conta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }
}
