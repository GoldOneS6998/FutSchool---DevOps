import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/widgets/auth_surface.dart';
import '../domain/auth_service.dart';
import '../domain/account_access.dart';
import 'register_page.dart';
import 'recovery_page.dart';
import '../../privacy/domain/privacy_repository.dart';
import '../../privacy/presentation/privacy_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.auth, this.privacy});
  final AuthService? auth;
  final PrivacyRepository? privacy;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool google = false}) async {
    if (_busy || widget.auth == null) return;
    if (!google && !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (google) {
        await widget.auth!.signInWithGoogle();
      } else {
        await widget.auth!.signIn(_email.text.trim(), _password.text);
      }
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.auth != null && !_busy;
    return AuthSurface(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AcademyLogo(),
              const SizedBox(height: 20),
              const Text(
                'FutSchool',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Inicia sesión para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(color: futText, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: futCard,
                  border: Border.all(color: futGreen),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Correo electrónico',
                      style: TextStyle(
                        color: futText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'nombre@ejemplo.com',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduce tu correo.';
                        }
                        if (value.trim().length > 254 ||
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value.trim())) {
                          return 'Introduce un correo válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Contraseña',
                      style: TextStyle(
                        color: futText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _obscure = !_obscure),
                          icon: _obscure
                              ? SvgPicture.asset('assets/figma/auth/eye.svg')
                              : const Icon(
                                  Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Introduce tu contraseña.'
                          : null,
                    ),
                    if (widget.auth case final AccountAccess account) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => RecoveryPage(
                                      account: account,
                                      email: _email.text.trim(),
                                    ),
                                  ),
                                ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: futGreen),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFFCA5A5)),
                  ),
                ),
              ],
              if (widget.auth == null) ...[
                const SizedBox(height: 16),
                const Text(
                  'El acceso estará disponible al conectar Firebase.',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: enabled ? () => _submit() : null,
                child: Text(_busy ? 'Conectando…' : 'Iniciar sesión'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: enabled ? () => _submit(google: true) : null,
                child: const Text('Continuar con Google'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RegisterPage(
                            auth: widget.auth,
                            privacy: widget.privacy,
                          ),
                        ),
                      ),
                child: const Text(
                  'Regístrate aquí',
                  style: TextStyle(color: futText, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.privacy != null)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PrivacyPage(repository: widget.privacy!),
                          ),
                        ),
                  child: const Text(
                    'Aviso de privacidad',
                    style: TextStyle(color: futText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
