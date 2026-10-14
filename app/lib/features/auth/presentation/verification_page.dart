import 'package:flutter/material.dart';

import '../../../shared/widgets/auth_surface.dart';
import '../domain/account_access.dart';
import '../domain/auth_service.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
    required this.account,
    required this.onSignOut,
  });
  final AccountAccess account;
  final Future<void> Function() onSignOut;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _busy = false;
  String? _message;
  Future<void> _run(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(() => _message = message);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message = 'No se pudo completar la operación. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AcademyLogo(),
        const SizedBox(height: 24),
        const Text(
          'Verifica tu correo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Abre el enlace de verificación antes de gestionar equipos o inscripciones. Después pulsa «Ya verifiqué mi correo».',
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(_message!)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(
                  widget.account.refreshVerification,
                  'Si ya lo confirmaste, se actualizará tu acceso.',
                ),
          child: const Text('Ya verifiqué mi correo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                  widget.account.sendVerification,
                  'Correo de verificación enviado. Revisa tu bandeja de entrada.',
                ),
          child: const Text('Reenviar verificación'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onSignOut, ''),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
}
