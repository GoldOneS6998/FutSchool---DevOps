import 'package:flutter/material.dart';

import '../../../shared/widgets/auth_surface.dart';
import '../domain/account_access.dart';
import '../domain/auth_service.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key, required this.account, this.email = ''});
  final AccountAccess account;
  final String email;
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.account.resetPassword(_email.text.trim());
      if (mounted) {
        setState(
          () => _message = 'Si el correo corresponde a una cuenta, recibirás instrucciones para recuperar el acceso.',
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No se pudo solicitar la recuperación. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthSurface(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AcademyLogo(),
          const SizedBox(height: 24),
          const Text(
            'Recuperar acceso',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escribe tu correo. Sigue el enlace que Firebase enviará para cambiar tu contraseña.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _email,
            enabled: !_busy,
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: (value) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(value?.trim() ?? '')
                ? null
                : 'Introduce un correo válido.',
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Semantics(liveRegion: true, child: Text(_message!)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Solicitando…' : 'Enviar instrucciones'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Volver al login'),
          ),
        ],
      ),
    ),
  );
}
